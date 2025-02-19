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
    private passengerContracts: Map<string, ShieldedContract> = new Map()

  
    constructor(config: AppConfig) {
      this.config = config
    }
  
    /**
     * Initialize the app.
     */
    async init() {
      for (const provider of this.config.providers) {
        const walletClient = await createShieldedWalletClient({
          chain: this.config.wallet.chain,
          transport: http(this.config.wallet.rpcUrl),
          account: privateKeyToAccount(provider.privateKey as `0x${string}`),
        })
        this.providerClients.set(provider.name, walletClient)
  
        const contract = await getShieldedContractWithCheck(
          walletClient,
          this.config.contract.abi,
          this.config.contract.address
        )
        this.providerContracts.set(provider.name, contract)
      }

      for (const passenger of this.config.passengers) {
        const walletClient = await createShieldedWalletClient({
          chain: this.config.wallet.chain,
          transport: http(this.config.wallet.rpcUrl),
          account: privateKeyToAccount(passenger.privateKey as `0x${string}`),
        })
        this.passengerClients.set(passenger.name, walletClient)
        
        const contract = await getShieldedContractWithCheck(
          walletClient,
          this.config.contract.abi,
          this.config.contract.address
        )
        this.passengerContracts.set(passenger.name, contract)
      }
    }
    

    /**
     * Get the shielded contract for a player.
     * @param passengerName - The name of the passenger.
     * @returns The shielded contract for the passenger.
     */
    private getPassengerName(passengerName: string): ShieldedContract {
      const contract = this.passengerContracts.get(passengerName)
      if (!contract) {
        throw new Error(`Shielded contract for passenger ${passengerName} not found`)
      }
      return contract
    }

    /**
     * Get the shielded contract for a player.
     * @param providerName - The name of the provider.
     * @returns The shielded contract for the provider.
     */
    private getProviderName(providerName: string): ShieldedContract {
      const contract = this.providerContracts.get(providerName)
      if (!contract) {
        throw new Error(`Shielded contract for passenger ${providerName} not found`)
      }
      return contract
    }

    /**
     * Underwrite a new flight insurance policy
     * @param insurerName - Name of the insurance provider
     * @param flightNumber - Flight number being insured
     * @param premium - Premium amount
     * @param coverage - Maximum payout amount
     */
    async underwritePolicy(insurerName: string, flightNumber: string, premium: bigint, coverage: bigint) {
      console.log(`- ${insurerName} underwriting policy for ${flightNumber}`)
      const contract = this.getProviderName(insurerName)
      await contract.write.underwritePolicy([flightNumber, premium, coverage])
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
  