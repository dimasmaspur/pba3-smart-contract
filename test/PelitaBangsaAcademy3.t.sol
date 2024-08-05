// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../src/PelitaBangsaAcademy3.sol";
import {PelitaBangsaAcademy3} from "../src/PelitaBangsaAcademy3.sol";

contract PelitaBangsaAcademy3Test is Test {
    PelitaBangsaAcademy3 villaRental;
    MockERC20 paymentToken;
    address owner = address(0x6858370F0002F8711ab4912e6ec293EB1b32dB34);
    address renter = address(0xe7a80B623c415f1F228d30863e15849e999ad9Dd);
   

    function setUp() public {
        paymentToken = new MockERC20("PaymentToken", "PTK");
        villaRental = new PelitaBangsaAcademy3(address(paymentToken), 100 * 10**18, owner);

        // Mint and approve tokens for renter
        paymentToken.mint(renter, 1000 * 10**18);
        vm.prank(renter);
        paymentToken.approve(address(villaRental), type(uint256).max);
    }

    function testInitialization() public view {
        assertEq(villaRental.paymentToken(), address(paymentToken));
        assertEq(villaRental.villaPricePerDay(), 100 * 10**18);
        assertEq(villaRental.owner(), owner);
    }

    function testRentVillaValid() public {
        vm.startPrank(renter);
        villaRental.rentVilla(5); // Rent for 5 days
        vm.stopPrank();

        (uint256 daysRented, uint256 startTimestamp, uint256 endTimestamp) = villaRental.getStatus(renter);
        assertEq(daysRented, 5);
        assertEq(endTimestamp, startTimestamp + 5 days);
        assertEq(paymentToken.balanceOf(address(villaRental)), 500 * 10**18);
        assertEq(villaRental.balanceOf(renter), 500 * 10**18);
    }

    function testRentVillaZeroDays() public {
        vm.startPrank(renter);
        vm.expectRevert("Rental duration must be greater than zero");
        villaRental.rentVilla(0); // Rent for 0 days
        vm.stopPrank();
    }

    function testRentVillaInsufficientPayment() public {
        vm.startPrank(renter);
        paymentToken.transfer(address(0xdead), paymentToken.balanceOf(renter) - 400 * 10**18); // Drain renter's tokens
        vm.expectRevert("Insufficient payment");
        villaRental.rentVilla(5); // Rent for 5 days without enough balance
        vm.stopPrank();
    }

    function testGetStatusForNonRenter() public view {
        (uint256 daysRented, uint256 startTimestamp, uint256 endTimestamp) = villaRental.getStatus(address(0x789));
        assertEq(daysRented, 0);
        assertEq(startTimestamp, 0);
        assertEq(endTimestamp, 0);
    }

    function testWithdrawTokensAsOwner() public {
        vm.startPrank(owner);
        villaRental.withdrawTokens(address(paymentToken));
        vm.stopPrank();

        assertEq(paymentToken.balanceOf(owner), 500 * 10**18);
        assertEq(paymentToken.balanceOf(address(villaRental)), 0);
    }

    function testWithdrawTokensAsNonOwner() public {
        vm.startPrank(renter);
        vm.expectRevert("Ownable: caller is not the owner");
        villaRental.withdrawTokens(address(paymentToken));
        vm.stopPrank();
    }

    function testWithdrawTokensWithNoBalance() public {
        vm.startPrank(owner);
        paymentToken.transfer(address(0xdead), paymentToken.balanceOf(address(villaRental))); // Drain contract's balance
        vm.expectRevert("No tokens to withdraw");
        villaRental.withdrawTokens(address(paymentToken));
        vm.stopPrank();
    }

    function testSetVillaPricePerDayAsOwner() public {
        vm.startPrank(owner);
        villaRental.setVillaPricePerDay(200 * 10**18); // Set new villa price per day
        assertEq(villaRental.villaPricePerDay(), 200 * 10**18);
        vm.stopPrank();
    }

    function testSetVillaPricePerDayAsNonOwner() public {
        vm.startPrank(renter);
        
        vm.expectRevert();
        villaRental.setVillaPricePerDay(200 * 10**18);
        vm.stopPrank();
    }
}
