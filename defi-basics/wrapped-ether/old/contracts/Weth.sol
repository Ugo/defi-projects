// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Weth is ERC20 {
    constructor() ERC20('Wrapped Ether', 'WETH') {}

    // simply mint the same amount sent to the contract for the sender
    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }

    // to withdraw, simply check that the sender has enough tokens, burn them and send real ether
    function withdraw(uint amount) external {
        require(balanceOf(msg.sender) >= amount, 'Balance too low');
        _burn(msg.sender, amount);
        msg.sender.transfer(amount);
    }
}
