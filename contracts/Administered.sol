pragma solidity ^0.4.11;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';

contract Administered is Ownable {

  mapping(address => bool) private administrators;

  event LogAdminAdded(address indexed newAdmin, address indexed byAdmin);
  event LogAdminRemoved(address indexed oldAdmin, address indexed byAdmin);

  modifier fromAdministrator {
    require(administrators[msg.sender]);
    _;
  }

  function Administered() {
    administrators[msg.sender] = true;
  }

  function addAdministrator(address _newAdmin)
    fromAdministrator()
    public
    returns(bool success)
  {
    administrators[_newAdmin] = true;
    LogAdminAdded(_newAdmin,msg.sender);
    return true;
  }

  function removeAdministrator(address _oldAdmin)
    fromAdministrator()
    public
    returns(bool success)
  {
    require(_oldAdmin != owner);
    administrators[_oldAdmin] = false;
    LogAdminAdded(_oldAdmin,msg.sender);
    return true;
  }

}
