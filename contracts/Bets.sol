// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ownable.sol";

contract Bets is Ownable {
  //address public poolCommissions;
  //uint public CommissionPercentage = 10;
    uint balance = 0;
    uint betsCounter = 0;
    uint puntersCounter = 0;

    enum State {ACTIVE, FINALIZED}
    enum Winner {A, B, DRAW, UNDEFINED}

    struct Bet {
        uint betId;
        uint poolA; //0: A, 1: B, 3: Draw 
        uint poolB;
        uint poolDraw;
        string optionA;
        string optionB;
        string optionC;
        State state;
        Winner winner;
    }
    struct Punter {
        uint punterId;
        address payable account;
        uint betId;
        uint choiceId;
        uint amount; 
    }

    mapping (uint256 => Bet) public bets;
    mapping (uint256 => Punter) public punters;

    event BetCreated(
        uint betId,
        uint poolA,
        uint poolB,
        uint poolDraw,
        string optionA,
        string optionB,
        string optionC,
        State state,
        Winner winner
    );

    event Constructor(
        string messeger
    );

    constructor() {
        ownable();
        emit Constructor("keep building pa!");
    }

    function createBet(string memory a, string memory b) public onlyOwner() {
        bets[betsCounter++] =
             Bet(betsCounter, 0, 0, 0, a, b, "Draw", State.ACTIVE, Winner.UNDEFINED);

        emit BetCreated(betsCounter, 0, 0, 0, a, b, "Draw", State.ACTIVE, Winner.UNDEFINED);
    }

    /**
        choice: 0 => optionA, 1 => optionB, 2 => optionDraw
     */
    function bet(uint betId, uint choice) external payable isValid(betId) {
        require(msg.value > 0 && (choice >= 0 && choice <= 2));
       
        payable(owner).transfer(msg.value);
        punters[puntersCounter++] = Punter({
            punterId: puntersCounter,
            account: payable(msg.sender),
            betId: betId,
            choiceId: choice,
            amount: msg.value
        });
        if (choice == 0) {
            bets[betId].poolA += msg.value; //TODO menos el fee
        } else if (choice == 1) {
            bets[betId].poolB += msg.value;
        } else if (choice == 2) {
            bets[betId].poolDraw += msg.value;
        }
        balance += msg.value;
    }

    function getPunters(uint _betId, uint option) public view  isValid(_betId) returns (Punter [] memory, uint size) {
        Punter[] memory toReturn;
        uint counter = 0;
        for (uint i = 0; i <= puntersCounter; i++) {
            if (punters[i].betId == _betId) {
                if(punters[i].choiceId == option) {
                    toReturn[counter++] = punters[i];
                }
            }
        }
        return (toReturn, counter);
    }

    function setWinner(uint _betId, Winner winner) private isValid(_betId) onlyOwner() {
        bets[_betId].winner = winner;
        bets[_betId].state = State.FINALIZED;
        uint poolWinners;
        
        poolWinners = bets[_betId].poolA + bets[_betId].poolB + bets[_betId].poolDraw;

        distributeProfit(_betId, poolWinners);
    }

    function distributeProfit(uint _betId, uint poolWinners) private onlyOwner() isValid(_betId) {
        if (bets[_betId].winner == Winner.A) {
            distributeAux(_betId, 0, poolWinners);
        } else if (bets[_betId].winner == Winner.B) {
            distributeAux(_betId, 1, poolWinners);
        } else if (bets[_betId].winner == Winner.DRAW) {
            distributeAux(_betId, 2, poolWinners);
        }
    } 

    function refound(uint _betId) public onlyOwner() isValid(_betId) {
        distributeAux(_betId, 0, 0);
        distributeAux(_betId, 1, 0);
        distributeAux(_betId, 2, 0);
    }

    function distributeAux(uint _betId, uint option, uint poolWinners) private onlyOwner() isValid(_betId) {
         Punter[] memory punter;
         uint size;
        (punter,size) = getPunters(_betId, option);
        for (uint i = 0; i < size; i++) {
            sendProfit(_betId, punter[i].account, punter[i].amount, poolWinners);
        }
    }

    function sendProfit(uint _betId, address payable winner, uint amount, uint poolWinners) private isValid(_betId) {
        if(bets[_betId].state == State.ACTIVE) { //is refound
            require(balance >= amount);
            winner.transfer(amount);
            balance -= amount;
        } else { //is not refound
            uint profit = calculateProfit(_betId, amount, poolWinners);
            require(balance >= profit);
            winner.transfer(profit);
            balance -= profit;
        }
    }

    function calculateProfit(uint _betId, uint amount, uint poolWinners) private view returns (uint) {
        uint poolPunters = 0;
        if (bets[_betId].winner == Winner.A) {
            poolPunters = bets[_betId].poolA;
        } else if (bets[_betId].winner == Winner.B) {
            poolPunters = bets[_betId].poolB;
        } else if (bets[_betId].winner == Winner.DRAW) {
            poolPunters = bets[_betId].poolDraw;
        }
        return (amount / poolPunters) * poolWinners; //TODO menos el fee
    }

    modifier isValid(uint betId) {
        require(betId >= 0 && betId < betsCounter);
        _;
    }
}