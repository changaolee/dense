const dataRepository = artifacts.require("DataRepository");

module.exports = function (deployer) {
    deployer.deploy(dataRepository);
};