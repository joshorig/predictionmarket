pragma solidity ^0.4.11;

import './HubbedOwnable.sol';

contract Administered is HubbedOwnable {

  mapping(address => bool) private administrators;

  event LogAdminAdded(address indexed newAdmin, address indexed byAdmin);
  event LogAdminRemoved(address indexed oldAdmin, address indexed byAdmin);

  modifier fromAdministrator(address _originator) {
    require(administrators[_originator]);
    _;
  }

  function Administered(address _originator)
  HubbedOwnable(_originator)
  {
    administrators[_originator] = true;
  }

  function addAdministrator(address _originator, address _newAdmin)
    onlyHub
    fromAdministrator(_originator)
    public
    returns(bool success)
  {
    administrators[_newAdmin] = true;
    LogAdminAdded(_newAdmin,_originator);
    return true;
  }

  function removeAdministrator(address _originator, address _oldAdmin)
    onlyHub
    fromAdministrator(_originator)
    public
    returns(bool success)
  {
    require(_oldAdmin != owner);
    administrators[_oldAdmin] = false;
    LogAdminAdded(_oldAdmin,_originator);
    return true;
  }

}
