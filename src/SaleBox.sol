// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";


contract SaleBox {
    /*
    *
    * SaleBox
    *
    * @description
    * 1) register token with providing token address, lot size  and lot price
    * 2) approve salebox contract to spend tokens (ERC20.approve(box, amount))
    * 3) send ETH (native coins) to salebox
    */
    event Register(uint256 id, address token, uint256 amount, uint256 price);
    event Unregister(uint256 id);
    event SetPrice(uint256 id, uint256 amount, uint256 price);

    struct TokenInfo {
        uint256 price;
        address token;
        uint256 amount; // how many tokens per price
        address owner;
    }
    mapping(uint256 => TokenInfo) tokenInfo;
    address[] tokens;

    function available(uint256 id) public view returns (uint256) {
        ERC20 token = ERC20(tokenInfo[id].token);
        address owner = tokenInfo[id].owner;
        uint256 balance = token.balanceOf(owner);
        uint256 allowance = token.allowance(owner, address(this));
        if(balance < allowance) {
            return balance;
        }
        return allowance;
    }

    function register(address token, uint256 amount, uint256 price) public {
        tokens.push(token);
        uint256 id = tokens.length - 1;
        tokenInfo[id] = TokenInfo(
            price,
            token,
            amount,
            msg.sender
        );
        emit Register(id, token, amount, price);
    }

    function unregister(uint256 id) public {
        require(tokenInfo[id].owner == msg.sender, "SaleBox::unregister: not owner");
        tokens[id] = tokens[tokens.length - 1];
        tokens.pop();
        delete tokenInfo[id];
        emit Unregister(id);
    }

    function setPrice(uint256 id, uint256 amount, uint256 price) public {
        require(tokenInfo[id].owner == msg.sender, "SaleBox::setPrice: not owner");
        tokenInfo[id].price = price;
        tokenInfo[id].amount = amount;
        emit SetPrice(id, amount, price);
    }

    receive() external payable {
        // only first register may be used in fallback
        TokenInfo memory info = tokenInfo[0];
        uint256 amount = msg.value * info.amount / info.price; 
        require(amount > 0, "SaleBox::buy: invalid amount");
        require(address(info.token) != address(0), "SaleBox::buy: invalid token");
        require(available(0) >= amount, "SaleBox::buy: insufficient balance");
        SafeTransferLib.safeTransferETH(info.owner, msg.value);
        SafeTransferLib.safeTransferFrom(ERC20(info.token), info.owner, msg.sender, amount);
    }


    function buy(uint256 id, uint256 quantity) public payable {
        ERC20 token = ERC20(tokenInfo[id].token);
        address owner = tokenInfo[id].owner;
        uint256 amount = tokenInfo[id].amount * quantity;
        require(address(token) != address(0), "SaleBox::buy: invalid token");
        require(tokenInfo[id].price * quantity == msg.value, "SaleBox::buy: not enough");
        require(available(id) >= amount, "SaleBox::buy: insufficient balance");
        SafeTransferLib.safeTransferETH(owner, msg.value);
        SafeTransferLib.safeTransferFrom(token, owner, msg.sender, amount);
    }
}
