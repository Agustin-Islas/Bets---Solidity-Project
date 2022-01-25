const BetsContract = artifacts.require("Bets");

module.exports = function (deployer) {
  deployer.deploy(BetsContract);
};
