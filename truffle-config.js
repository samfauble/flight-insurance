var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "vendor quiz pig battle asthma save thing brave decide super almost bridge";

module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:9545/", 0, 50);
      },
      network_id: '*',
      gas: 9999999
    }
  },
  compilers: {
    solc: {
      version: "^0.6.0"
    }
  }
};
