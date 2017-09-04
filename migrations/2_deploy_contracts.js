var SafeMath = artifacts.require('zeppelin-solidity/contracts/math/SafeMath.sol');
var PredictionMarket = artifacts.require("./PredictionMarket.sol");

module.exports = function(deployer) {
  deployer.deploy(SafeMath);
  deployer.link(SafeMath, PredictionMarket);
  deployer.deploy(PredictionMarket);
};
