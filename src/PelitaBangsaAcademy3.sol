// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract PelitaBangsaAcademy3 is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    uint256 public villaPricePerDay;

    struct Rental {
        uint256 daysRented;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 tokensEarned;
    }

    // Mapping to track villa renters and their rental information
    mapping(address => Rental) public rentals;

    // Events
    event Rented(
        address indexed renter,
        uint256 rentalDays,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    constructor(
        uint256 _villaPricePerDay,
        address initialOwner
    )
        ERC20("VillaToken", "VLT")
        ERC20Permit("VillaToken")
        Ownable(initialOwner)
    {
        villaPricePerDay = _villaPricePerDay;
        _mint(msg.sender, 10000000000 * 10 ** decimals()); // Minting initial supply to the owner
    }

    function rentVilla(uint256 rentalDays) public payable {
        require(rentalDays > 0, "Rental duration must be greater than zero");

        // Calculate the total payment in ETH
        uint256 totalPayment = villaPricePerDay * rentalDays;

        // Ensure the sent ETH is sufficient
        require(msg.value >= totalPayment, "Insufficient ETH sent");

        // Transfer the ETH to the owner
        payable(owner()).transfer(totalPayment);

        // If the user sent more ETH than required, refund the excess
        if (msg.value > totalPayment) {
            payable(msg.sender).transfer(msg.value - totalPayment);
        }

        // Mint 1 VLT token per rental day to the renter's wallet
        uint256 tokensToMint = rentalDays * 10 ** decimals();
        _mint(msg.sender, tokensToMint);

        // Calculate rental period
        uint256 startTimestamp = block.timestamp;
        uint256 endTimestamp = startTimestamp + (rentalDays * 1 days);

        // Update rentals mapping
        rentals[msg.sender] = Rental({
            daysRented: rentalDays,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp,
            tokensEarned: tokensToMint
        });

        emit Rented(msg.sender, rentalDays, startTimestamp, endTimestamp);
    }

    function withdrawETH() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Updated getStatus function with the public visibility specifier
    function getStatus(address renter) public view returns (address, uint256, uint256, uint256, uint256) {
        Rental memory rental = rentals[renter];
        return (renter, rental.daysRented, rental.startTimestamp, rental.endTimestamp, rental.tokensEarned);
    }

    function setVillaPricePerDay(uint256 _villaPricePerDay) public onlyOwner {
        villaPricePerDay = _villaPricePerDay;
    }
}
