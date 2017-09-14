var SafeMath = artifacts.require('zeppelin-solidity/contracts/math/SafeMath.sol');
var PredictionMarketHub = artifacts.require("./PredictionMarketHub.sol");

module.exports = function(deployer) {
  deployer.deploy(PredictionMarketHub);
};
