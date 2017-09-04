pragma solidity ^0.4.11;

import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract Terminable is Ownable {
    function terminate() onlyOwner {
        selfdestruct(owner);
    }
}
