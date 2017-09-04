pragma solidity ^0.4.11;


import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './Administered.sol';
import './Terminable.sol';

contract PredictionMarket is Administered,Terminable {

	enum Answers { None, Yes, No }

	struct QuestionStruct {
	 string question;
	 address trustedSource;
	 uint deadline;
	 Answers answer;
	 bool suspend;
	 uint totalYes;
	 uint totalNo;
	 uint multiplyer;
	 uint remainder;
	}

	struct BetStruct {
	 uint amountYes;
	 uint amountNo;
	}

  mapping (bytes32 => QuestionStruct) public questions;
	mapping (address => mapping (bytes32 => BetStruct)) public bets;

	event LogNewQuestion(bytes32 questionId, string question, address indexed trustedSource, uint deadline, address indexed administrator);
	event LogBet(bytes32 questionId, address indexed gambler, uint amount, bool guess);
	event LogQuestionAnswered(bytes32 questionId, bool answer, address indexed trustedSource);
	event LogBettingSuspended(bytes32 questionId, address indexed administrator);

	function addNewQuestion(bytes32 _questionId, string _question, address _trustedSource, uint _duration)
	public
	fromAdministrator
	returns (bool success)
	{
		require(_trustedSource != address(0));
		QuestionStruct questionStruct = questions[_questionId];
		require(questionStruct.trustedSource == address(0)); //do not use previously used Id
		uint deadline = block.number+_duration;
		questionStruct.answer = Answers.None;
		questionStruct.question = _question;
		questionStruct.trustedSource = _trustedSource;
		questionStruct.deadline = deadline;
		LogNewQuestion(_questionId,_question,_trustedSource,deadline,msg.sender);
		return true;
	}

	function bet(bytes32 _questionId, bool _guess)
	public
	payable
	returns (bool success)
	{
		QuestionStruct questionStruct = questions[_questionId];
		require(questionStruct.trustedSource != address(0)); //Question should exist
		require(questionStruct.answer == Answers.None && !questionStruct.suspend);
		require(msg.sender != questionStruct.trustedSource); //trusted source cannot bet
		BetStruct betStruct = bets[msg.sender][_questionId];
		if(_guess)
		{
			betStruct.amountYes = SafeMath.add(betStruct.amountYes,msg.value);
			questionStruct.totalYes = SafeMath.add(questionStruct.totalYes,msg.value);
		}
		else
		{
			betStruct.amountNo = SafeMath.add(betStruct.amountNo,msg.value);
			questionStruct.totalNo = SafeMath.add(questionStruct.totalNo,msg.value);
		}
		LogBet(_questionId,msg.sender,msg.value,_guess);
		return true;
	}

	function answerQuestion(bytes32 _questionId, bool _answer)
	public
	returns (bool success)
	{
		QuestionStruct questionStruct = questions[_questionId];
		require(msg.sender == questionStruct.trustedSource); //only trusted source can asnwer
		require(questionStruct.answer == Answers.None);
		require(questionStruct.deadline >= block.number);

		uint totalAmount = SafeMath.add(questionStruct.totalYes,questionStruct.totalNo);

		if(_answer)
		{
			questionStruct.answer = Answers.Yes;
			questionStruct.multiplyer = totalAmount / questionStruct.totalYes;
      questionStruct.remainder = totalAmount % questionStruct.totalYes;
		}
		else
		{
			questionStruct.answer = Answers.No;
			questionStruct.multiplyer = totalAmount / questionStruct.totalNo;
      questionStruct.remainder = totalAmount % questionStruct.totalNo;
		}
		LogQuestionAnswered(_questionId,_answer,msg.sender);
		return true;
	}

	function claimWinnings(bytes32 _questionId)
	public
	returns (bool success)
	{
		BetStruct betStruct = bets[msg.sender][_questionId];
		QuestionStruct questionStruct = questions[_questionId];
		require((betStruct.amountYes > 0 && questionStruct.answer == Answers.Yes) || (betStruct.amountNo > 0 && questionStruct.answer == Answers.No)); //Need to have winning bet
		uint winnings;
		uint multipliedPart;
		uint remainderPart;
		if(questionStruct.answer == Answers.Yes)
		{
			multipliedPart = SafeMath.mul(betStruct.amountYes,questionStruct.multiplyer);
			remainderPart = SafeMath.mul(betStruct.amountYes,questionStruct.remainder) / questionStruct.totalYes;
			winnings = SafeMath.add(multipliedPart,remainderPart);
		}
		else
		{
			multipliedPart = SafeMath.mul(betStruct.amountNo,questionStruct.multiplyer);
			remainderPart = SafeMath.mul(betStruct.amountNo,questionStruct.remainder) / questionStruct.totalNo;
			winnings = SafeMath.add(multipliedPart,remainderPart);
		}
		require(winnings > 0);
		betStruct.amountYes = 0;
		betStruct.amountNo = 0;
		msg.sender.transfer(winnings);
		return true;
	}

	function claimRefund(bytes32 _questionId)
	public
	returns (bool success)
	{
		BetStruct betStruct = bets[msg.sender][_questionId];
		require(betStruct.amountYes > 0 || betStruct.amountNo > 0); //Need to have made a bet
		QuestionStruct questionStruct = questions[_questionId];
		require(questionStruct.answer == Answers.None && questionStruct.deadline<block.number);
		uint refundAmount = SafeMath.add(betStruct.amountYes,betStruct.amountNo);
		betStruct.amountYes = 0;
		betStruct.amountNo = 0;
		msg.sender.transfer(refundAmount);
		return true;
	}

	function suspendBetting(bytes32 _questionId)
	public
	fromAdministrator
	returns (bool success)
	{
		QuestionStruct questionStruct = questions[_questionId];
		require(questionStruct.answer == Answers.None && !questionStruct.suspend); //can only suspend a live question
		questionStruct.suspend = true;
		LogBettingSuspended(_questionId,msg.sender);
		return true;
	}

	function unSuspendBetting(bytes32 _questionId)
	public
	fromAdministrator
	returns (bool success)
	{
		QuestionStruct questionStruct = questions[_questionId];
		require(questionStruct.answer == Answers.None && questionStruct.suspend); //can only unsuspend a suspended question
		questionStruct.suspend = false;
		LogBettingSuspended(_questionId,msg.sender);
		return true;
	}

}
