pragma solidity ^0.7.3;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract CollateralBackedToken is ERC20 {
    IERC20 public collateral;
    uint public price = 1;

    constructor(address _collateral) ERC20('Collateral Backed Token', 'CBT') {
        collateral = IERC20(collateral);
    }

    // send the amount of ERC20 token to this contract's address, then mint the matching amount of CBT for the sender.
    function deposit(uint collateralAmount) external {
        collateral.transferFrom(msg.sender, address(this), collateralAmount);
        _mint(msg.sender, collateralAmount * price);
    }

    // the withdraw will check that the balance is enough, burn the matching amount of CBT token and finally transfer back 
    // the original amount of collateralized tokens.
    function withdraw(uint tokenAmount) external {
        require(balanceOf(msg.sender) >= tokenAmount, 'Balance too low');
        _burn(msg.sender, tokenAmount);
        collateral.transfer(tokenAmount / price);
    }

}