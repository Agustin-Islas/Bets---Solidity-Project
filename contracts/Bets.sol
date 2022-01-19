// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ownable.sol";

contract Bets is Ownable {
  //address public poolCommissions;
  //uint public CommissionPercentage = 10;
    uint public balance;
    uint betsCounter = 0;
    uint puntersCounter = 0;

    struct Bet {
        uint[3] poolsRewards; //0: A, 1: B, 3: Draw 
        string[3] options;
        uint8 state; //0: active, 1: finalized //TODO enum
        uint8 winner;
    }
    struct Punter {
        address payable account;
        uint betId;
        uint choiceId;
        uint amount; 
    }

    mapping (uint256 => Bet) bets;
    mapping (uint => Punter) punters;

    function createBet(string memory a, string memory b) public onlyOwner() {
        string[3] memory options;
        options[0] = a;
        options[1] = b;
        options[2] = "draw";
        uint[3] memory pools;
        pools[0] = 0;
        pools[1] = 0;
        pools[2] = 0;
        bets[betsCounter++] = Bet(pools, options, 0, 3);
    }

    function bet(uint betId, uint choice, address payable from) external payable isValid(betId) {
        require(msg.value > 0 && choice >= 0 && choice < 3);
        owner.transfer(msg.value);
        punters[puntersCounter++] = Punter({
            account: from,
            betId: betId,
            choiceId: choice,
            amount: msg.value
        });
        bets[betId].poolsRewards[choice] += msg.value; //TODO menos el fee
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

    function setWinner(uint _betId, uint winner) private isValid(_betId) onlyOwner() {
        require(winner >= 0 && winner <= 2);
        bets[_betId].winner = uint8(winner);
        bets[_betId].state = 1;
        uint poolWinners;
        for (uint i = 0; i < 3; i++) {
            poolWinners += bets[_betId].poolsRewards[i];
        }
        distributeProfit(_betId, poolWinners);
    }

    function distributeProfit(uint _betId, uint poolWinners) private onlyOwner() isValid(_betId) {
        distributeAux(_betId, bets[_betId].winner, poolWinners);
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
        if(bets[_betId].state == 0) { //is refound
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
        uint poolPunters = bets[_betId].poolsRewards[bets[_betId].winner];
        return (amount / poolPunters) * poolWinners; //TODO menos el fee
    }

    modifier isValid(uint betId) {
        require(betId >= 0 && betId < betsCounter);
        _;
    }
}