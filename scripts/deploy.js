const hre = require('hardhat');

async function main() {
  const CrowdFunding = await ethers.getContractFactory('CrowdFunding');
  console.log('Deploying Contract...');
  const crowdFunding = await CrowdFunding.deploy();
  await crowdFunding.deployed();
  console.log(`Deployed Contract to : ${crowdFunding.address}`);
  console.log(`Contract Deployed`);
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
