pragma solidity ^0.4.18;

contract Test {
    uint8 public number;

    event Event(uint8 newNum);

    function Test(uint8 num) public {
        number = num;
    }

    function getNum() view public returns (uint8) {
        return number;
    }

    function setNum(uint8 num) public {
        number = num;
        Event(number);
    }
}
