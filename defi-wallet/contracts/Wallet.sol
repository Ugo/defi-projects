pragma solidity ^0.7.3;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './Compound.sol';

contract Wallet is Compound {
    address public admin;

    constructor(
        address _comptroller,
        address _cEthAddress
    ) Compound(_comptroller, _cEthAddress) {
        admin = msg.sender;
    }

    
    function deposit(address cTokenAddress, uint underlyingAmount) external {
        address underlyingAddress = getUnderlyingAddress(cTokenAddress);
        IERC20(underlyingAddress).transferFrom(msg.sender, address(this), underlyingAmount);
        supply(cTokenAddress, underlyingAmount);
    }

    function withdraw(
        address cTokenAddress,
        uint underlyingAmount,
        address recipient
    ) onlyAdmin() external {
        require(getUnderlyingBalance(cTokenAddress) >= underlyingAmount, 'balance too low');
        
        // claim the comp tokens that should be received at withdraw time because some tokens have been supplied
        claimComp();

        // send the tokens to the recipient
        redeem(cTokenAddress, underlyingAmount);
        address underlyingAddress = getUnderlyingAddress(cTokenAddress);
        IERC20(underlyingAddress).transfer(recipient, underlyingAmount);
        
        // and send the comp tokens to the recipient as well
        address compAddress = getCompAddress();
        IERC20 compToken = IERC20(compAddress);
        uint compAmount = compToken.balanceOf(address(this));
        compToken.transfer(recipient, compAmount);
    }

    // call every time some ether is sent to the contract
    // the full amount is simply supplied to compound
    receive() external payable {
        supplyEth(msg.value);
    }

    function withdrawETH(
        uint underlyingAmount, 
        address payable recipient
    ) onlyAdmin() external {
        require(getUnderlyingEthBalance() >= underlyingAmount, 'balance too low');
        
        // get the comp tokens earned and redeem the ETH
        claimComp();
        redeemEth(underlyingAmount);

        // transfer both to the recipient - first ETH
        recipient.transfer(underlyingAmount);
        // then Comp token
        address compAddress = getCompAddress();
        IERC20 compToken = IERC20(compAddress);
        uint compAmount = compToken.balanceOf(address(this));
        compToken.transfer(recipient, compAmount);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        _;
    }
}
