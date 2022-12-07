const { ethers } = require("hardhat");
const hre = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  const multisigWallet = await hre.ethers.getContractFactory("MultiSigWallet");
  const multisig = await multisigWallet.deploy([
    "0x3bE4e93069ca7c467aEE2cd28b115C8f4022ef37",
    "0x90b7cC254D0e45A59a5894Ab27B01c388f37c1a8",
    "0xbD338d06EdF63d0cf576e3Fa602E6367CeD07028",
  ]);
  await multisig.deployed();
  console.log("nftMarketplace deployed to:", multisig.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
