var Catalog = artifacts.require("./Catalog.sol");

module.exports = function(deployer) {
  deployer.deploy(Catalog);
};
