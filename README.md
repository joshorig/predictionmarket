# ConsenSys Academy Module 5 Prediction Market

The project will start as a database whereby:

* as a regular user, you can create a prediction market for  dice roll games and become the markets owner
* as an owner, you can add and withdraw funds from the prediction market
* as an administrator, you can start a new dice roll game.
* as an administrator, you can set and update the winning odds on a dice roll game.
* a prediction market must have sufficient funds to pay out on any winning bets
* as a regular user you can bet on an outcome of a dice roll.
* as a administrator, you can trigger a dice roll for a specific game via OraclizeIt
* as a regular user, you can withdraw any winnings

* This project uses a hub & spoke model where the hub contract creates prediction markets (spokes) and handles the user interactions

## TODO

* Add more tests
* Add a UI to use new contract interface
