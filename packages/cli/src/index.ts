import dotenv from 'dotenv'
import { join } from 'path'
import { sanvil, seismicDevnet } from 'seismic-viem'

import { CONTRACT_DIR, CONTRACT_NAME } from '../lib/constants'
import { readContractABI, readContractAddress } from '../lib/utils'
import { App } from './app'

dotenv.config()

async function main() {
  if (!process.env.CHAIN_ID || !process.env.RPC_URL) {
    console.error('Please set your environment variables.')
    process.exit(1)
  }

  const broadcastFile = join(
    CONTRACT_DIR,
    'broadcast',
    `${CONTRACT_NAME}.s.sol`,
    process.env.CHAIN_ID,
    'run-latest.json'
  )
  const abiFile = join(
    CONTRACT_DIR,
    'out',
    `${CONTRACT_NAME}.sol`,
    `${CONTRACT_NAME}.json`
  )

  const chain =
    process.env.CHAIN_ID === sanvil.id.toString() ? sanvil : seismicDevnet

  const passengers = [
      { name: 'Alice', privateKey: process.env.ALICE_PRIVKEY! },
      { name: 'Bob', privateKey: process.env.BOB_PRIVKEY! },
      { name: 'Chad', privateKey: process.env.CHAD_PRIVKEY! },
      { name: 'Dave', privateKey: process.env.DAVE_PRIVKEY! },
      { name: 'Eve', privateKey: process.env.EVE_PRIVKEY! },
      { name: 'Frank', privateKey: process.env.FRANK_PRIVKEY! },
      { name: 'Grace', privateKey: process.env.GRACE_PRIVKEY! },
      { name: 'Heidi', privateKey: process.env.HEIDI_PRIVKEY! }
  ]

  const providers = [
      { name: 'Aaron', privateKey: process.env.AARON_PRIVKEY! },
      { name: 'Bella', privateKey: process.env.BELLA_PRIVKEY! },
      { name: 'Charlie', privateKey: process.env.CHARLIE_PRIVKEY! },
      { name: 'Diana', privateKey: process.env.DIANA_PRIVKEY! },
      { name: 'Ethan', privateKey: process.env.ETHAN_PRIVKEY! },
      { name: 'Fiona', privateKey: process.env.FIONA_PRIVKEY! }
  ]

  const flights = [
      { flightId: 1, departure: 'NYC', arrival: 'LAX' },
      { flightId: 2, departure: 'SFO', arrival: 'SEA' },
      { flightId: 3, departure: 'MIA', arrival: 'ORD' }
  ]

  const app = new App({
    providers,
    passengers,
    wallet: {
      chain,
      rpcUrl: process.env.RPC_URL!,
    },
    contract: {
      abi: readContractABI(abiFile),
      address: readContractAddress(broadcastFile),
    },
  })

  await app.init()


  // Simulating interactions between providers and passengers
  console.log('=== Creating policies ===')
  app.createPolicy(providers[0].name, 1, flights[0].flightId, BigInt(1e16), BigInt(1e20))
  app.createPolicy(providers[1].name, 2, flights[2].flightId, BigInt(1e17), BigInt(1e18))
  app.createPolicy(providers[2].name, 3, flights[1].flightId, BigInt(1e19), BigInt(1e20))
  app.createPolicy(providers[3].name, 4, flights[1].flightId, BigInt(1e18), BigInt(1e20))
  app.createPolicy(providers[4].name, 5, flights[0].flightId, BigInt(1e19), BigInt(1e20))
  app.createPolicy(providers[5].name, 6, flights[0].flightId, BigInt(1e17), BigInt(1e20))

  console.log('==== Buying policies ===')
  // Policy 1 has the lowest premium for flight with id 1
  app.buyPolicy(passengers[0].name, flights[0].flightId)

  // Now, if another user that's on the same flight tries to buy this policy would give an error
  console.error(app.buyPolicy(passengers[1].name, flights[0].flightId))

  // As there is only one policy the policy with id 2 will be sold
  app.buyPolicy(passengers[2].name, flights[2].flightId) 

  // For a passenger on flight with id 2, policy 4 will be sold
  app.buyPolicy(passengers[3].name, flights[1].flightId) // Policy 3
  app.buyPolicy(passengers[4].name, flights[1].flightId) // Policy 4

  // Error if someone now tries to call the buyPolicy function when there is no flight policy available
  console.error(app.buyPolicy(passengers[5].name, flights[1].flightId))
}

main()
