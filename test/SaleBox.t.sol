// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "solmate/tokens/WETH.sol";
import "../src/SaleBox.sol";

contract SaleBoxTest is Test {
    uint256 forkId;
    WETH weth = WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
    address alice;
    SaleBox box;
    address bob;

    function setUp() public {
        string memory MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        forkId = vm.createSelectFork(MAINNET_RPC_URL);
        box = new SaleBox();
        alice = address(1);
        bob = address(2);

        vm.label(address(weth), "WETH");
        vm.label(address(box), "Box");
        vm.label(address(alice), "Alice");
        vm.label(address(bob), "Bob");

        deal(address(weth), alice, 10 ether);

        // alice's approves
        vm.startPrank(alice);
        weth.approve(address(box), weth.balanceOf(alice));
        vm.stopPrank();

    }

    function testFallbackCall() public {
        vm.startPrank(alice);
        weth.approve(address(box), weth.balanceOf(alice));
        box.register(address(weth), 10, 1);
        vm.stopPrank();
        uint256 aliceWethBalance = weth.balanceOf(alice);
        uint256 bobWethBalance = weth.balanceOf(bob);
        uint256 aliceEthBalance = payable(alice).balance;
        uint256 bobEthBalance = payable(bob).balance;

        vm.startPrank(bob);
        assertEq(bobWethBalance, 0 ether);
        payable(address(box)).call{value: 1 ether}("");
        assertEq(weth.balanceOf(bob), 10 ether);
        assertEq(weth.balanceOf(alice), aliceWethBalance - 10 ether);
        assertEq(payable(bob).balance, bobEthBalance - 1 ether);
        assertEq(payable(alice).balance, aliceEthBalance + 1 ether);
        vm.stopPrank();
    }

    function test() public {
        vm.startPrank(alice);
        weth.approve(address(box), weth.balanceOf(alice));
        box.register(address(weth), 10, 1);
        vm.stopPrank();
        uint256 aliceWethBalance = weth.balanceOf(alice);
        uint256 bobWethBalance = weth.balanceOf(bob);
        uint256 aliceEthBalance = payable(alice).balance;
        uint256 bobEthBalance = payable(bob).balance;

        vm.startPrank(bob);
        assertEq(bobWethBalance, 0 ether);
        box.buy{value: 1 ether}(0, 1e18);
        assertEq(weth.balanceOf(bob), 10 ether);
        assertEq(weth.balanceOf(alice), aliceWethBalance - 10 ether);
        assertEq(payable(bob).balance, bobEthBalance - 1 ether);
        assertEq(payable(alice).balance, aliceEthBalance + 1 ether);
        vm.stopPrank();
    }
}
