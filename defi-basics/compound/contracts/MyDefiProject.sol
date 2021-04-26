pragma solidity ^0.7.3;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './CTokenInterface.sol';
import './ComptrollerInterface.sol';
import './PriceOracleInterface.sol';

contract MyDefiProject {
    ComptrollerInterface public comptroller;
    PriceOracleInterface public priceOracle;

    constructor(
        address _comptroller,
        address _priceOracle
    ) {
        comptroller = ComptrollerInterface(_comptroller);
        priceOracle = PriceOracleInterface(_priceOracle);
    }

    // function to lend token on compound (that will be used as collateral)
    function supply(address cTokenAddress, uint underlyingAmount ) public {
        CTokenInterface cToken = CTokenInterface(cTokenAddress);
        address underlyingAddress = cToken.underlying(); 
        IERC20(underlyingAddress).approve(cTokenAddress, underlyingAmount);
        uint result = cToken.mint(underlyingAmount);
        require(
            result == 0, 
            'cToken#mint() failed. see Compound ErrorReporter.sol for details'
        );
    }

    // function to redeem the tokens that have been lent to compound (the opposite of the supply method)
    function redeem(address cTokenAddress, uint cTokenAmount) external {
        CTokenInterface cToken = CTokenInterface(cTokenAddress);
        uint result = cToken.redeem(cTokenAmount);
        require(
            result == 0,
            'cToken#redeem() failed. see Compound ErrorReporter.sol for more details'
        );
    }

    // function to indicate to compound which token will be used as collateral
    // function to be called once some tokens have been lent to compound
    function enterMarket(address cTokenAddress) external {
        address[] memory markets = new address[](1);
        markets[0] = cTokenAddress; 
        uint[] memory results = comptroller.enterMarkets(markets);
        require(
            results[0] == 0, 
            'comptroller#enterMarket() failed. see Compound ErrorReporter.sol for details'
        ); 
    }

    // function to borrow tokens once the market has been entered
    // parameters are the address of the token to borrow and the amount we want to borrow
    function borrow(address cTokenAddress, uint borrowAmount) external {
        CTokenInterface cToken = CTokenInterface(cTokenAddress);
        address underlyingAddress = cToken.underlying(); 
        uint result = cToken.borrow(borrowAmount);
        require(
            result == 0, 
            'cToken#borrow() failed. see Compound ErrorReporter.sol for details'
        ); 
    }

    // function to repay the loan to compound
    function repayBorrow(address cTokenAddress, uint underlyingAmount) external {
        CTokenInterface cToken = CTokenInterface(cTokenAddress);
        address underlyingAddress = cToken.underlying(); 
        IERC20(underlyingAddress).approve(cTokenAddress, underlyingAmount);
        uint result = cToken.repayBorrow(underlyingAmount);
        require(
            result == 0, 
            'cToken#borrow() failed. see Compound ErrorReporter.sol for details'
        ); 
    }

    // function to get the max amount of tokens that can be borrowed
    function getMaxBorrow(address cTokenAddress) external view returns(uint) {
        (uint result, uint liquidity, uint shortfall) = comptroller
            .getAccountLiquidity(address(this));
        require(
            result == 0, 
            'comptroller#getAccountLiquidity() failed. see Compound ErrorReporter.sol for details'
        ); 
        require(shortfall == 0, 'account underwater');
        require(liquidity > 0, 'account does not have collateral');
        uint underlyingPrice = priceOracle.getUnderlyingPrice(cTokenAddress);
        return liquidity / underlyingPrice;
    }
}