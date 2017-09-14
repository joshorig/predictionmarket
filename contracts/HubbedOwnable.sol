pragma solidity ^0.4.11;


/**
 * @title Ownable
 * @dev The HubbedOwnable contract has a hub and an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract HubbedOwnable {
  address public hub;
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The HubbedOwnable constructor sets the `hub` of the contract to the sender
   * account (hub contract) and the owner to the orginal message sender (end user) _originator
   */
  function HubbedOwnable(address _originator) {
    hub = msg.sender;
    owner = _originator;
  }


  /**
   * @dev Throws if @param _originator is any account other than the owner.
   */
  modifier onlyOwner(address _originator) {
    require(_originator == owner);
    _;
  }

  /**
   * @dev Throws if called by any account other than the hub.
   */
  modifier onlyHub() {
    require(msg.sender == hub);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _originator, address newOwner)
  onlyHub
  onlyOwner(_originator)
  {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
