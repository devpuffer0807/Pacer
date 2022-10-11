/* eslint-disable no-console */

import { ethers } from 'hardhat'

async function main() {
  const depoStakingFactory = await ethers.getContractFactory('DepoStaking')

  const rewardToken = '0x01547ef97f9140dbdf5ae50f06b77337b95cf4bb'
  const stakingToken = '0x01547ef97f9140dbdf5ae50f06b77337b95cf4bb'
  const rewardTotal = 10000
  const startTime = Math.floor(Date.now() / 1000)
  const depoStakingContract = await depoStakingFactory.deploy(rewardToken, stakingToken, rewardTotal, startTime)
  await depoStakingContract.deployed()
  console.log(startTime)
  console.log('DepoStaking Contract Deployed To:', depoStakingContract.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
