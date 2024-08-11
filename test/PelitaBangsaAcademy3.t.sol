// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {PelitaBangsaAcademy3} from "../src/PelitaBangsaAcademy3.sol";

contract PelitaBangsaAcademy3Test is Test {
    PelitaBangsaAcademy3 villaRental;
    address owner = address(0x6858370F0002F8711ab4912e6ec293EB1b32dB34);
    address renter = address(0xe7a80B623c415f1F228d30863e15849e999ad9Dd);

    function setUp() external {
        villaRental = new PelitaBangsaAcademy3(100 * 10**18, owner);
    }

    function testInitialization() external {
        assertEq(villaRental.villaPricePerDay(), 100 * 10**18);
        assertEq(villaRental.owner(), owner);
    }

    function testRentVillaValid() external {
        uint256 initialOwnerBalance = owner.balance;
        uint256 rentalDays = 1;
        uint256 totalPayment = rentalDays * villaRental.villaPricePerDay();

        // Set initial balance for the renter
        vm.deal(renter, totalPayment);
        
        // Start prank as the renter
        vm.startPrank(renter);
        villaRental.rentVilla{value: totalPayment}(rentalDays); // Rent for 1 day
        vm.stopPrank();

        // Check the rental details
        ( , uint256 daysRented, uint256 startTimestamp, uint256 endTimestamp, uint256 tokensEarned) = villaRental.getStatus(renter);
        assertEq(daysRented, rentalDays);
        assertEq(endTimestamp, startTimestamp + 1 days);
        
        // Check if the owner's balance has increased correctly
        assertEq(owner.balance, initialOwnerBalance + totalPayment);

        // Check if the renter received the correct amount of VLT tokens
        assertEq(villaRental.balanceOf(renter), rentalDays * 10 ** villaRental.decimals());
        assertEq(tokensEarned, rentalDays * 10 ** villaRental.decimals());
    }

    function testRentVillaZeroDays() external {
        vm.startPrank(renter);
        vm.expectRevert(); // Expect any revert, without specifying an error message
        villaRental.rentVilla{value: 100 * 10**18}(0); // Rent for 0 days
        vm.stopPrank();
    }

    function testRentVillaInsufficientPayment() external {
        uint256 rentalDays = 5;
        uint256 insufficientPayment = 2 * villaRental.villaPricePerDay();

        vm.deal(renter, insufficientPayment);
        vm.startPrank(renter);
        vm.expectRevert("Insufficient ETH sent");
        villaRental.rentVilla{value: insufficientPayment}(rentalDays); // Rent for 5 days without enough balance
        vm.stopPrank();
    }

    function testGetStatusForNonRenter() external {
        ( , uint256 daysRented, uint256 startTimestamp, uint256 endTimestamp, uint256 tokensEarned) = villaRental.getStatus(address(0x789));
        assertEq(daysRented, 0);
        assertEq(startTimestamp, 0);
        assertEq(endTimestamp, 0);
        assertEq(tokensEarned, 0);
    }

    function testWithdrawETHAsOwner() external {
        uint256 rentalDays = 5;
        uint256 totalPayment = rentalDays * villaRental.villaPricePerDay();

        // Deal some ETH to renter and let them rent
        vm.deal(renter, totalPayment);
        vm.startPrank(renter);
        villaRental.rentVilla{value: totalPayment}(rentalDays);
        vm.stopPrank();

        // Withdraw ETH as owner
        uint256 initialOwnerBalance = owner.balance;
        vm.startPrank(owner);
        villaRental.withdrawETH();
        vm.stopPrank();

        // Check if the owner received the correct amount of ETH after withdrawal
        assertEq(owner.balance, initialOwnerBalance + totalPayment);
    }

    function testWithdrawETHAsNonOwner() external {
        vm.startPrank(renter);
        vm.expectRevert("Ownable: caller is not the owner");
        villaRental.withdrawETH();
        vm.stopPrank();
    }

    function testSetVillaPricePerDayAsOwner() external {
        vm.startPrank(owner);
        villaRental.setVillaPricePerDay(200 * 10**18); // Set new villa price per day
        assertEq(villaRental.villaPricePerDay(), 200 * 10**18);
        vm.stopPrank();
    }

    function testSetVillaPricePerDayAsNonOwner() external {
        vm.startPrank(renter);
        vm.expectRevert();
        villaRental.setVillaPricePerDay(200 * 10**18);
        vm.stopPrank();
    }
}
