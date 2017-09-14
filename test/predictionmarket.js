require('babel-polyfill');
const utils = require('./helpers/Utils');
const PredictionMarketHub = artifacts.require("./PredictionMarketHub.sol");
const PredictionMarket = artifacts.require("./PredictionMarket.sol");

contract('PredictionMarket', function(accounts) {

  var predictionMarketHub;
  var predictionMarketAddress;
  var createPredictionMarketTxObject;
  var predictionMarket;
  const ownerAccount = accounts[0];
  const newAdminAccount = accounts[1];
  const nonAdminAccount = accounts[2];
  const fundsToAddInWei = 1000;
  const gameId = web3.sha3("game1");
  const multiplier = 2;
  const updatedMultiplier = 4;
  const maxBet = web3.toWei(10,"ether");
  const duration = 5;

  beforeEach(async () => {
    predictionMarketHub = await PredictionMarketHub.deployed();
    createPredictionMarketTxObject = await predictionMarketHub.createPredictionMarket();
    predictionMarketAddress = createPredictionMarketTxObject.logs[0].args.predictionMarket;
    var abi = PredictionMarket.abi;
    return  web3.eth.contract(abi).at(predictionMarketAddress, function (err, _predictionMarket) {
      predictionMarket = _predictionMarket;
    });
  });

  it("Should create a predictionMarket", async () => {

    utils.getEventsPromise(predictionMarketHub.LogNewPredictionMarket({}, { fromBlock: web3.eth.blockNumber }))
    .then(function (events) {
      assert.equal(events.length,1,"Did not log LogNewPredictionMarket event");
      let logEvent = events[0];
      assert.equal(logEvent.args.owner,ownerAccount,"Did not log owner correctly");
      assert.equal(logEvent.args.predictionMarket,predictionMarketAddress,"Did not log predictionMarket correctly");
    });

  });

  it("Should add administrator correctly", async () => {
    let txObject = await predictionMarketHub.addAdministrator(predictionMarketAddress,newAdminAccount, {from: ownerAccount});

    utils.getEventsPromise(predictionMarket.LogAdminAdded({}, { fromBlock: web3.eth.blockNumber }))
    .then(function (events) {
      assert.equal(events.length,1,"Did not log LogAdminAdded event");
      let logEvent = events[0];
      assert.equal(logEvent.args.newAdmin,newAdminAccount,"Did not log newAdmin correctly");
      assert.equal(logEvent.args.byAdmin,ownerAccount,"Did not log byAdmin correctly");
    });

  });

  it("Should not allow non admin to add a new administrator", async () => {
    try {
     let txObject = await predictionMarketHub.addAdministrator(predictionMarketAddress, newAdminAccount, {from: nonAdminAccount, gas: utils.exceptionGasToUse});
     assert.equal(txObject.receipt.gasUsed, utils.exceptionGasToUse, "should have used all the gas");
    }
    catch (error){
      return utils.ensureException(error);
    }
  });

  it("Should add funds to market correctly", async () => {
    let txObject = await predictionMarketHub.addMarketFunds(predictionMarketAddress, {from: ownerAccount, value: fundsToAddInWei});

    utils.getEventsPromise(predictionMarket.LogMarketFundsAdded({}, { fromBlock: web3.eth.blockNumber }))
    .then(function (events) {
      assert.equal(events.length,1,"Did not log LogMarketFundsAdded event");
      let logEvent = events[0];
      assert.equal(logEvent.args.owner,ownerAccount,"Did not log owner correctly");
      assert.equal(logEvent.args.amount.valueOf(),fundsToAddInWei,"Did not log amount correctly");
    });

  });

  it("Should not allow non owner to add funds to market", async () => {
    try {
     let txObject = await predictionMarketHub.addMarketFunds(predictionMarketAddress, {from: nonAdminAccount, value: fundsToAddInWei, gas: utils.exceptionGasToUse});
     assert.equal(txObject.receipt.gasUsed, utils.exceptionGasToUse, "should have used all the gas");
    }
    catch (error){
      return utils.ensureException(error);
    }
  });

  it("Should allow admin to create a new dice game", async () => {
    await predictionMarketHub.addAdministrator(predictionMarketAddress,newAdminAccount, {from: ownerAccount});
    let txObject = await predictionMarketHub.addNewDiceGame(predictionMarketAddress,gameId,multiplier,maxBet,duration,{from: newAdminAccount});

    utils.getEventsPromise(predictionMarket.LogNewDiceGame({}, { fromBlock: web3.eth.blockNumber }))
    .then(function (events) {
      assert.equal(events.length,1,"Did not log LogNewDiceGame event");
      let logEvent = events[0];
      assert.equal(logEvent.args.gameId,gameId,"Did not log gameId correctly");
      assert.equal(logEvent.args.multiplyer.valueOf(),multiplyer,"Did not log multiplyer correctly");
      assert.equal(logEvent.args.maxBet.valueOf(),maxBet,"Did not log maxBet correctly");
      assert.equal(logEvent.args.deadline.valueOf(),deadline,"Did not log deadline correctly");
      assert.equal(logEvent.args.administrator,newAdminAccount,"Did not log administrator correctly");
    });
  });

    it("Should not allow non admin to create a new dice game", async () => {
      try {
        let txObject = await predictionMarketHub.addNewDiceGame(predictionMarketAddress,gameId,multiplier,maxBet,duration,{from: nonAdminAccount});
        assert.equal(txObject.receipt.gasUsed, utils.exceptionGasToUse, "should have used all the gas");
      }
      catch (error){
        return utils.ensureException(error);
      }
    });

});
