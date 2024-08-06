// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PelitaBangsaAcademy3 is ERC20, ERC20Burnable, Ownable, ERC20Permit {
    address public paymentToken;
    uint256 public villaPricePerDay;

    struct Rental {
        uint256 daysRented;
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    // Mapping to track villa renters and their rental information
    mapping(address => Rental) public rentals;

    // Events
    event Rented(
        address indexed renter,
        uint256 amount,
        uint256 rentalDays,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    constructor(
        address _paymentToken,
        uint256 _villaPricePerDay,
        address initialOwner
    )
        ERC20("VillaToken", "VLT")
        ERC20Permit("VillaToken")
        Ownable(initialOwner) // Pass the initial owner to the Ownable constructor
    {
        paymentToken = _paymentToken;
        villaPricePerDay = _villaPricePerDay;
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }

    // Updated rentVilla function to be payable
    function rentVilla(uint256 rentalDays) public payable {
        require(rentalDays > 0, "Rental duration must be greater than zero");

        uint256 totalPayment = villaPricePerDay * rentalDays;
        require(msg.value == totalPayment, "Incorrect Ether value sent");

        // Calculate rental period
        uint256 startTimestamp = block.timestamp;
        uint256 endTimestamp = startTimestamp + (rentalDays * 1 days);

        // Update rentals mapping
        rentals[msg.sender] = Rental({
            daysRented: rentalDays,
            startTimestamp: startTimestamp,
            endTimestamp: endTimestamp
        });

        // Mint custom tokens for the renter
        _mint(msg.sender, totalPayment);

        emit Rented(msg.sender, totalPayment, rentalDays, startTimestamp, endTimestamp);
    }

    // Updated getStatus function to include the renter's address
    function getStatus(address renter) public view returns (address, uint256, uint256, uint256) {
        Rental memory rental = rentals[renter];
        return (renter, rental.daysRented, rental.startTimestamp, rental.endTimestamp);
    }

    function withdrawTokens(address tokenAddress) public onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        IERC20(tokenAddress).transfer(owner(), balance);
    }

    // New function to withdraw Ether collected from rent payments
    function withdrawEther() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No Ether to withdraw");
        payable(owner()).transfer(balance);
    }

    function setVillaPricePerDay(uint256 _villaPricePerDay) public onlyOwner {
        villaPricePerDay = _villaPricePerDay;
    }
}

// MockERC20 implementations
contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
 