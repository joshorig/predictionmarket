require('babel-polyfill');
const utils = require('./helpers/Utils');
const PredictionMarket = artifacts.require("./PredictionMarket.sol");

contract('PredictionMarket', function(accounts) {

  let predictionMarket;
  const ownerAccount = accounts[0];
  const newAdminAccount = accounts[1];
  const nonAdminAccount = accounts[2];

  beforeEach(async () => {
    predictionMarket = await PredictionMarket.deployed();
  });

  it("Should add administrator correctly", async () => {

    let txObject = await predictionMarket.addAdministrator(newAdminAccount, {from: ownerAccount});
    assert.equal(txObject.logs.length,1,"Did not log LogAdminAdded event");
    let logEvent = txObject.logs[0];
    assert.equal(logEvent.event,"LogAdminAdded","Did not LogAdminAdded");
    assert.equal(logEvent.args.newAdmin,newAdminAccount,"Did not log newAdmin correctly");
    assert.equal(logEvent.args.byAdmin,ownerAccount,"Did not log byAdmin correctly");
  });
});
