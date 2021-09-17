//Add these after react c=>
require('babel-register');
require('babel-polyfill');

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    ganache: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    solc: {
      // default is 0.5.16
      version: ">=0.4.24 <0.9.0",
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
};
