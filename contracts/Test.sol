pragma solidity ^0.4.18;

contract Test {
    uint8 public number;

    function Test(uint8 num) public {
        number = num;
    }

    function getNum() view public returns (uint8) {
        return number;
    }

    function setNum(uint8 num) public {
        number = num;
    }
}
