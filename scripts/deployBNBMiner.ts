// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  
  const _treasury1 = "0x5Ce4c97C4Ab2dE8698A5Ca2C277f8e2cb468e71A"; // deployer can set this address
  const _treasury2 = "0x5Ce4c97C4Ab2dE8698A5Ca2C277f8e2cb468e71A";

  const BNBMiner = await ethers.getContractFactory("BNBMiner");
  const bnbMiner = await BNBMiner.deploy(_treasury1, _treasury2);

  await bnbMiner.deployed();

  console.log("BNBMiner deployed to:", bnbMiner.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
