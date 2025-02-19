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
    { flightNumber: 'FL123', departure: 'NYC', arrival: 'LAX' },
    { flightNumber: 'FL456', departure: 'SFO', arrival: 'SEA' },
    { flightNumber: 'FL789', departure: 'MIA', arrival: 'ORD' }
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

  // Simulating multiplayer interactions
  console.log('=== Round 1 ===')
  await app.shake('Alice', 2)
  await app.hit('Alice')
  await app.shake('Alice', 4)
  await app.hit('Alice')
  await app.shake('Alice', 1)
  await app.hit('Alice')

  // Alice looks at the number in round 1, should be 7
  await app.look('Alice')

  console.log('=== Round 2 ===')
  await app.reset('Bob')
  await app.hit('Bob')
  await app.shake('Bob', 1)
  await app.hit('Bob')
  await app.shake('Bob', 2)
  await app.hit('Bob')

  // Bob looks at the number in round 2, should be 3
  await app.look('Bob')

  // Alice tries to look in round 2, should fail by reverting
  try {
    await app.look('Alice')
  } catch (error) {
    const errorMessage =
      error instanceof Error ? error.message : 'Unknown error'
    console.error('Alice could not call look() in round 2:', errorMessage)
  }
}

main()
