pragma solidity ^0.4.11;


import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './OraclizeAPI_0.4.sol';
import './Administered.sol';
import './Terminable.sol';

//Admins use oracalise to answer
//Admins must suspend better before answering
//Admins set odds on questions and can update those odds
//Each individual bet has its odds
//Bets must be able to be covered by market balance, owner can add funds to the market to cover any risk

contract PredictionMarket is Administered,usingOraclize {

	struct DiceGameStruct {
	 uint result; //result of oracalizeit dice roll
	 uint deadline;
	 bool suspend;
	 uint totalAmount;
	 uint currentmultiplier; //setting the odds, users will win amount bet * multiplier
	 uint maxBet;
	 uint[] payouts; //total payouts for each answer
	 uint maxPayout; //max to be paid out for this game
	}

	struct BetStruct {
	 address gambler;
	 bytes32 gameId;
	 uint guess;
	 uint amount;
	 uint multiplier;
	 uint amountPaid;
	}

  mapping (bytes32 => DiceGameStruct) public games;
	mapping (bytes32 => BetStruct) public bets;

	uint public balance; //markets funds
	uint public totalMaxAtRisk; //total of max payouts for each question - total amount bet on each question (or 0 if negative)
	bytes32 public diceWaitingForOraclize;

	event LogNewDiceGame(bytes32 gameId, uint multiplier, uint maxBet, uint deadline, address indexed administrator);
	event LogBet(bytes32 gameId, address indexed gambler, uint amount, uint guess);
	event LogBettingSuspended(bytes32 gameId, address indexed administrator);
	event LogBettingUnSuspended(bytes32 gameId, address indexed administrator);
	event LogMarketFundsAdded(address indexed owner, uint amount);
	event LogMarketFundsWithdrawn(address indexed owner, uint amount);
	event LogPayout(bytes32 betId, bytes32 gameId, address indexed gambler, uint amount);
	event LogRefund(bytes32 betId, bytes32 gameId, address indexed gambler, uint amount);
	event LogOraclizeQuery(string description);
	event LogDiceRolled(bytes32 gameId, uint answer);

	function PredictionMarket(address _originator)
	Administered(_originator)
	{

	}

	function addNewDiceGame(address _originator, bytes32 _gameId, uint _multiplier, uint _maxBet, uint _duration)
	public
	onlyHub
	fromAdministrator(_originator)
	returns (bool success)
	{
		require(_multiplier > 0 && _maxBet > 0);
		DiceGameStruct diceGameStruct = games[_gameId];
		require(diceGameStruct.currentmultiplier == 0); //do not use previously used Id
		uint deadline = block.number+_duration;
		diceGameStruct.currentmultiplier = _multiplier;
		diceGameStruct.maxBet = _maxBet;
		diceGameStruct.deadline = deadline;
		diceGameStruct.payouts = new uint[](5);
		LogNewDiceGame(_gameId,_multiplier,_maxBet,deadline,_originator);
		return true;
	}

	function addMarketFunds(address _originator)
	public
	onlyHub
	onlyOwner(_originator)
	payable
	returns (bool success)
	{
		balance = SafeMath.add(balance,msg.value);
		LogMarketFundsAdded(_originator,msg.value);
		return true;
	}

	function withdrawMarketFunds(address _originator, uint _amount)
	onlyHub
	onlyOwner(_originator)
	returns (bool success)
	{
		uint availableBalance = SafeMath.sub(balance,totalMaxAtRisk);
		require(availableBalance<=_amount);
		balance = SafeMath.sub(balance,_amount);
		_originator.transfer(_amount);
		LogMarketFundsWithdrawn(_originator,_amount);
		return true;
	}

	function bet(bytes32 _betId, bytes32 _gameId, uint _guess)
	public
	payable
	returns (bool success)
	{
		BetStruct betStruct = bets[_betId];
		require(betStruct.gambler == address(0)); //_betId must be unique
		require(_guess >= 1 && _guess <= 6); //_guess within range 1-6
		DiceGameStruct diceGameStruct = games[_gameId];
		require(diceGameStruct.currentmultiplier >0); //Question should exist
		require(diceGameStruct.result == 0 && !diceGameStruct.suspend);
		require(msg.value <= diceGameStruct.maxBet);

		//Check we have required balance to cover risk
		uint betPayout = SafeMath.mul(diceGameStruct.currentmultiplier,msg.value);
		uint updatedPayout = SafeMath.add(diceGameStruct.payouts[_guess-1],betPayout);
		if(updatedPayout > diceGameStruct.maxPayout)
		{
			uint difference = SafeMath.sub(updatedPayout,diceGameStruct.maxPayout);
			diceGameStruct.maxPayout = updatedPayout;
			totalMaxAtRisk = SafeMath.add(totalMaxAtRisk,difference);
		}

		assert(totalMaxAtRisk<balance); //We cannot accept bets that we cannot cover/payout


		betStruct.gambler = msg.sender;
		betStruct.gameId = _gameId;
		betStruct.guess = _guess;
		betStruct.multiplier = diceGameStruct.currentmultiplier;
		betStruct.amount = msg.value;

		LogBet(_gameId,msg.sender,msg.value,_guess);
		return true;
	}

	function rollDice(address _originator, bytes32 _gameId)
	public
	onlyHub
	fromAdministrator(_originator)
	returns (bool success)
	{
		DiceGameStruct diceGameStruct = games[_gameId];
		require(diceGameStruct.currentmultiplier >0); //Question should exist
		require(diceGameStruct.result == 0); //question has not been answered
		require(diceWaitingForOraclize == 0); //we can only answer one question at a time
		require(diceGameStruct.deadline >= block.number);

		assert(suspendBetting(_originator,_gameId)); //We need to suspend betting since the answer could be made visible before the block is mined
		diceWaitingForOraclize = _gameId;

		LogOraclizeQuery("Oraclize query was sent, standing by for the answer..");
    oraclize_query("WolframAlpha", "random number between 1 and 6");
		return true;
	}

	function __callback(bytes32 myid, string result)
  {
    require(msg.sender == oraclize_cbAddress());

		bytes32 gameId = diceWaitingForOraclize;
    diceWaitingForOraclize = 0;

		DiceGameStruct diceGameStruct = games[gameId];
		require(diceGameStruct.currentmultiplier >0); //Question should exist
		require(diceGameStruct.result == 0); //question has not been answered
		uint diceRoll = parseInt(result);
		uint payout = betStruct.payouts[diceRoll];
		if(payout > 0)
		{
			balance = SafeMath.sub(totalMaxAtRisk,balance);
			totalMaxAtRisk = SafeMath.sub(totalMaxAtRisk,payout);
		}
		diceGameStruct.result = diceRoll;
		LogDiceRolled(gameId,diceRoll);
	}

	function claimWinnings(bytes32 _betId)
	public
	returns (bool success)
	{
		BetStruct betStruct = bets[_betId];
		require(msg.sender == betStruct.gambler); //Only payout the actor who made the bet
		DiceGameStruct diceGameStruct = games[betStruct.gameId];
		require(diceGameStruct.result > 0 && betStruct.guess == diceGameStruct.result); //question has been answered and the bet was correct
		require(betStruct.amountPaid == 0); //bet must not have already been paid out
		uint winnings = SafeMath.mul(betStruct.amount,betStruct.multiplier);
		require(winnings > 0);
		betStruct.amountPaid = winnings;
		msg.sender.transfer(winnings);
		LogPayout(_betId,betStruct.gameId,msg.sender,winnings);
		return true;
	}

	function claimRefund(bytes32 _betId)
	public
	returns (bool success)
	{
		BetStruct betStruct = bets[_betId];
		require(msg.sender == betStruct.gambler); //Only refund the actor who made the bet
		DiceGameStruct diceGameStruct = games[betStruct.gameId];
		require(diceGameStruct.result == 0 && diceGameStruct.deadline<block.number);// Only if question if unanswered and expired
		require(betStruct.amount > 0);
		uint refundAmount = betStruct.amount;
		betStruct.amount = 0;
		msg.sender.transfer(refundAmount);
		LogRefund(_betId,betStruct.gameId,msg.sender,refundAmount);
		return true;
	}

	function suspendBetting(address _originator, bytes32 _gameId)
	public
	onlyHub
	fromAdministrator(_originator)
	returns (bool success)
	{
		DiceGameStruct diceGameStruct = games[_gameId];
		require(diceGameStruct.result == 0 && !diceGameStruct.suspend); //can only suspend a live question
		diceGameStruct.suspend = true;
		LogBettingSuspended(_gameId,_originator);
		return true;
	}

	function unSuspendBetting(address _originator, bytes32 _gameId)
	public
	onlyHub
	fromAdministrator(_originator)
	returns (bool success)
	{
		DiceGameStruct diceGameStruct = games[_gameId];
		require(diceGameStruct.result == 0 && diceGameStruct.suspend); //can only unsuspend a suspended question
		diceGameStruct.suspend = false;
		LogBettingUnSuspended(_gameId,_originator);
		return true;
	}

}
