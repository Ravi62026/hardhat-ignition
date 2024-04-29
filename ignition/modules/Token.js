const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("TokenModule", (m) => {
  const tokenContract = m.contract("Token", [1000, "Silopi"] );

  return { tokenContract };
});
