// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {UserVault} from "../../src/vault/UserVault.sol";

contract ReentrantToken {
    mapping(address account => uint256 balance) public balanceOf;
    mapping(address owner => mapping(address spender => uint256 amount)) public allowance;

    UserVault public targetVault;
    bool public attackEnabled;
    bool public reentryBlocked;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function setAttack(UserVault vault, bool enabled) external {
        targetVault = vault;
        attackEnabled = enabled;
        reentryBlocked = false;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 approved = allowance[from][msg.sender];
        require(approved >= amount, "ALLOWANCE");
        allowance[from][msg.sender] = approved - amount;

        if (attackEnabled) {
            attackEnabled = false;
            try targetVault.deposit(1) {
                reentryBlocked = false;
            } catch {
                reentryBlocked = true;
            }
        }

        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(to != address(0), "ZERO_TO");
        require(balanceOf[from] >= amount, "BALANCE");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
    }
}
