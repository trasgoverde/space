var Space = artifacts.require("./Space.sol");


module.exports = async function(deployer) {
let addr = await web3.eth.getAccounts();
await deployer.deploy(Space, 1000000000);
let tokenInstance = await Space.deployed();
};