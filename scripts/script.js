// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const shiba = await hre.ethers.getContractFactory("stakeShibaV4");
  
  //Testing on demo token
  //const greeter = await upgrades.deployProxy(shiba,["0x782d8c5c0150bedc70d94fe6737763ede839f205",1000,1500,2500],{initializer: 'initialize'});
  const greeter = await upgrades.upgradeProxy("0x18447D9e200b493F43634320CED4b8e837AC5B4d",shiba)
  await greeter.deployed();

  console.log("Contract deployed to:", greeter.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

