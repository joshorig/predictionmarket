pragma solidity ^0.4.11;

import "./PredictionMarket.sol";

contract PredictionMarketHub {

  address[] public predictionMarkets;
  mapping(address => bool) public predictionMarketExists;

  event LogNewPredictionMarket(address indexed owner, address indexed predictionMarket);

  modifier onlyIfPredictionMarket(address _predictionMarketAddress) {
      require(predictionMarketExists[_predictionMarketAddress] == true);
      _;
  }

  function createPredictionMarket()
  public
  returns(address predictionMarketContract)
  {
    PredictionMarket newPredictionMarket;

    newPredictionMarket = new PredictionMarket(msg.sender);
    predictionMarkets.push(newPredictionMarket);
    predictionMarketExists[newPredictionMarket] = true;

    LogNewPredictionMarket(msg.sender, address(newPredictionMarket));
    return address(newPredictionMarket);
  }

  function addAdministrator(address _predictionMarketAddress, address _newAdmin)
  public
  onlyIfPredictionMarket(_predictionMarketAddress)
  returns (bool success)
  {
    PredictionMarket predictionMarket = PredictionMarket(_predictionMarketAddress);
    assert(predictionMarket.addAdministrator(msg.sender,_newAdmin));
    return true;
  }

  function addMarketFunds(address _predictionMarketAddress)
  public
  onlyIfPredictionMarket(_predictionMarketAddress)
  payable
  returns (bool success)
  {
    PredictionMarket predictionMarket = PredictionMarket(_predictionMarketAddress);
    assert(predictionMarket.addMarketFunds.value(msg.value)(msg.sender));
    return true;
  }

  function addNewDiceGame(address _predictionMarketAddress, bytes32 _gameId, uint _multiplyer, uint _maxBet, uint _duration)
  public
  onlyIfPredictionMarket(_predictionMarketAddress)
  returns (bool success)
  {
      PredictionMarket predictionMarket = PredictionMarket(_predictionMarketAddress);
      assert(predictionMarket.addNewDiceGame(msg.sender,_gameId,_multiplyer,_maxBet,_duration));
      return true;
  }

}
