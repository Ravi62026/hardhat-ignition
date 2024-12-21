// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OverflowVulnerable {
    uint8 public maxUint8 = 255;

    function increment() public {
        maxUint8 += 1; // Overflow happens here
    }
}

contract underflowVulnerable {
    uint8 public minUint8 = 0;

    function decreament() public {
        minUint8 -= 1;
    }
}