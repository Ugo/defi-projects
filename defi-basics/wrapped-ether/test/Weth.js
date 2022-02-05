const { expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require("chai");
const { ethers, waffle} = require("hardhat");
const provider = waffle.provider;


describe('Weth contract', function() {
    let Weth;

    beforeEach(async function() {
      Weth = await ethers.getContractFactory("Weth");
      [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

      // weth will be the instance of the deployed contract
      weth = await Weth.deploy();
    });

    describe("Basic tests", function () {
      it('should deposit successfully', async () => {
          // deposit the real ether in the contract with addr1
          await weth.connect(addr1).deposit({value: 100});

          // check the balance of WETH for this address
          expect(await weth.balanceOf(addr1.address)).to.equal(100);

          // check the ETH value in the smart contract
          expect(await provider.getBalance(weth.address)).to.equal(100);
      });

      it('should withdraw successfully', async () => {
          // deposit real ether in the contract
          await weth.connect(addr1).deposit({value: 100});
          expect(await weth.balanceOf(addr1.address)).to.equal(100);

          // withdraw the ETH from the contract and check that it remains 0
          await weth.connect(addr1).withdraw(100);
          expect(await weth.balanceOf(addr1.address)).to.equal(0);

          // check the ETH value in the smart contract is then null
          expect(await provider.getBalance(weth.address)).to.equal(0);
      });

      it('should throw error if amount to withdraw is too big', async () => {
          // try to withdraw too much ETH from the contract
          await weth.connect(addr1).deposit({value: 50});
          await weth.connect(addr2).deposit({value: 100});

          // check that an error is thrown
          await expect(
            weth.connect(addr1).withdraw(100)
          ).to.be.revertedWith("Balance too low");

          // verifiy the amount for addr1 and in the contract
          expect(await weth.balanceOf(addr1.address)).to.equal(50);
          expect(await provider.getBalance(weth.address)).to.equal(150);

      });
    });
});
