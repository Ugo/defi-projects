const { expectRevert } = require('@openzeppelin/test-helpers');
const Weth = artifacts.require('Weth');

contract('Weth', (accounts) => {
    let weth;
    const [account1, account2] = [accounts[1], accounts[2]];
    
    beforeEach(async () => {
      weth = await Weth.new();
    });

    it('should deposit', async () => {
        // deposit the real ether in the contract
        await weth.deposit({from: account1, value: 100});
        
        // check the balance of WETH for this address
        let wethBalance = web3.utils.toBN(
            await weth.balanceOf(account1)
        );
        assert(wethBalance.toString() === '100');

        // check the ETH value in the smart contract
        const contractBalance = parseInt(await web3.eth.getBalance(weth.address));
        assert(contractBalance === 100);
    });

    it('should withdraw', async () => {
        // deposit real ether in the contract
        await weth.deposit({from: account1, value: 100});
        let wethBalance = web3.utils.toBN(
            await weth.balanceOf(account1)
        );
        
        // withdraw the ETHfrom the contract
        await weth.withdraw(100, {from: account1});
        wethBalance = web3.utils.toBN(
            await weth.balanceOf(account1)
        );
        assert(wethBalance.toString() === '0');

        // check the ETH value in the smart contract is then null
        const contractBalance = parseInt(await web3.eth.getBalance(weth.address));
        assert(contractBalance === 0);
    });

    it('should throw error if amount to withdraw is too big', async () => {
        // try to withdraw too much ETH from the contract
        await weth.deposit({from: account1, value: 50});
        await weth.deposit({from: account2, value: 100});
        await expectRevert(
            weth.withdraw(100, {from: account1}),
            'Balance too low'
        );
    });
});