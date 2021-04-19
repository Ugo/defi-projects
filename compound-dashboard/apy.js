import Compound from '@compound-finance/compound-js';

const provider = 'https://mainnet.infura.io/v3/4f330ad96d6f4931ad40b929f626b7c0';

const comptroller = Compound.util.getAddress(Compound.Comptroller);
const opf = Compound.util.getAddress(Compound.PriceFeed);

const cTokenDecimals = 8;
const blocksPerDay = 4 * 60 * 24; // one block every 15sec
const daysPerYear = 365;
const ethMantissa = Math.pow(10, 18);

async function calculateSupplyApy(cToken) {
    const supplyRatePerBlock = await Compound.eth.read(
        cToken, 
        'function supplyRatePerBlock() returns(uint)',
        [],
        {provider}
    );
    // by default the supplyRatePerBlock is multiplied by 10**18
    // so it needs to be divided to be used

    // compounding the rates for everyday
    return 100 * (Math.pow((supplyRatePerBlock / ethMantissa * blocksPerDay) + 1, daysPerYear - 1) - 1);
}

async function calculateCompApy(cToken, ticker, underlyingDecimals) {
    
    // get all the data needed from the smart contract
    let compSpeed = await Compound.eth.read(
        comptroller, 
        'function compSpeeds(address cToken) public returns(uint)',
        [ cToken ],
        { provider }
    );

    let compPrice = await Compound.eth.read(
        opf, 
        'function price(string memory symbol) external view returns(uint)',
        [ Compound.COMP ],
        { provider }
    );

    let underlyingPrice = await Compound.eth.read(
        opf, 
        'function price(string memory symbol) external view returns(uint)',
        [ ticker ],
        { provider }
    );

    let totalSupply = await Compound.eth.read(
        cToken, 
        'function totalSupply() public view returns(uint)',
        [],
        { provider }
    );

    let exchangeRate = await Compound.eth.read(
        cToken, 
        'function exchangeRateCurrent() public returns(uint)',
        [],
        { provider }
    );

    // all the values from the smart contract needs to get some adjustment.
    exchangeRate = +exchangeRate.toString() / ethMantissa; 
    compSpeed = compSpeed / 1e18; // COMP has 18 decimal places
    compPrice = compPrice / 1e6;  // price feed is USD price with 6 decimal places
    underlyingPrice = underlyingPrice / 1e6;
    totalSupply = (+totalSupply.toString() * exchangeRate * underlyingPrice) / (Math.pow(10, underlyingDecimals));
    const compPerDay = compSpeed * blocksPerDay;

    // no compounding here
    return 100 * (compPrice * compPerDay / totalSupply) * 365;
}

async function calculateApy(cTokenTicker, underlyingTicker) {
    const underlyingDecimals = Compound.decimals[cTokenTicker];
    const cTokenAddress = Compound.util.getAddress(cTokenTicker);
    const [supplyApy, compApy] = await Promise.all([
        calculateSupplyApy(cTokenAddress),
        calculateCompApy(cTokenAddress, underlyingTicker, underlyingDecimals)
    ]);

    return {ticker: underlyingTicker, supplyApy, compApy};
}

export default calculateApy;