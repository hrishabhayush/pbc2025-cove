import {
    type ShieldedContract,
    type ShieldedWalletClient,
    createShieldedWalletClient,
  } from 'seismic-viem'
  import { Abi, Address, Chain, http } from 'viem'
  import { privateKeyToAccount } from 'viem/accounts'
  
  import { getShieldedContractWithCheck } from '../lib/utils'
  
/**
 * The configuration for the app.
 */
interface AppConfig {
    providers: Array<{
        name: string
        privateKey: string
    }>
    passengers: Array<{
        name: string
        privateKey: string
    }>
    wallet: {
        chain: Chain
        rpcUrl: string
    }
    contract: {
        abi: Abi
        address: Address
    }
}
  
  /**
   * The main application class.
   */
  export class App {
    private config: AppConfig
    private providerClients: Map<string, ShieldedWalletClient> = new Map()
    private providerContracts: Map<string, ShieldedContract> = new Map()
    private passengerClients: Map<string, ShieldedWalletClient> = new Map()
    private passengerClients: Map<string, ShieldedContract> = new Map()

  
    constructor(config: AppConfig) {
      this.config = config
    }
  
    /**
     * Initialize the app.
     */
    async init() {
      for (const player of this.config.players) {
        const walletClient = await createShieldedWalletClient({
          chain: this.config.wallet.chain,
          transport: http(this.config.wallet.rpcUrl),
          account: privateKeyToAccount(player.privateKey as `0x${string}`),
        })
        this.playerClients.set(player.name, walletClient)
  
        const contract = await getShieldedContractWithCheck(
          walletClient,
          this.config.contract.abi,
          this.config.contract.address
        )
        this.playerContracts.set(player.name, contract)
      }
    }
  
    /**
     * Get the shielded contract for a player.
     * @param playerName - The name of the player.
     * @returns The shielded contract for the player.
     */
    private getPlayerContract(playerName: string): ShieldedContract {
      const contract = this.playerContracts.get(playerName)
      if (!contract) {
        throw new Error(`Shielded contract for player ${playerName} not found`)
      }
      return contract
    }
  
    /**
     * Reset the walnut.
     * @param playerName - The name of the player.
     */
    async reset(playerName: string) {
      console.log(`- Player ${playerName} writing reset()`)
      const contract = this.getPlayerContract(playerName)
      await contract.write.reset([])
    }
  
    /**
     * Shake the walnut.
     * @param playerName - The name of the player.
     * @param numShakes - The number of shakes.
     */
    async shake(playerName: string, numShakes: number) {
      console.log(`- Player ${playerName} writing shake()`)
      const contract = this.getPlayerContract(playerName)
      await contract.write.shake([numShakes])
    }
  
    /**
     * Hit the walnut.
     * @param playerName - The name of the player.
     */
    async hit(playerName: string) {
      console.log(`- Player ${playerName} writing hit()`)
      const contract = this.getPlayerContract(playerName)
      await contract.write.hit([])
    }
  
    /**
     * Look at the walnut.
     * @param playerName - The name of the player.
     */
    async look(playerName: string) {
      console.log(`- Player ${playerName} reading look()`)
      const contract = this.getPlayerContract(playerName)
      const result = await contract.read.look()
      console.log(`- Player ${playerName} sees number:`, result)
    }
  }
  