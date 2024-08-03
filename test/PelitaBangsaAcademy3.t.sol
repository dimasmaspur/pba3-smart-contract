// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {PelitaBangsaAcademy3} from "src/PelitaBangsaAcademy3.sol";

contract PelitaBangsaAcademy3Test is Test {
  PelitaBangsaAcademy3 public instance;

  function setUp() public {
    address initialOwner = vm.addr(1);
    instance = new PelitaBangsaAcademy3(initialOwner);
  }

  function testName() public view {
    assertEq(instance.name(), "Pelita Bangsa Academy 3");
  }
}
