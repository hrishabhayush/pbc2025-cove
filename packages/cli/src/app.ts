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
     * @param providerName - Name of the insurer/provider
     * @param policyId - Id of the policy
     * @param flightId - Id of the flight
     * @param premium - Premium amount
     * @param coverage - Coverage that is the flight's price
     */
    async createPolicy(
      providerName: string, 
      policyId: number,
      flightId: number, 
      premium: number, 
      coverage: number
    ) {
      console.log(`- ${providerName} underwriting policy for ${flightId}`)
      const contract = this.getProviderName(providerName)
      await contract.write.createPolicy([policyId, flightId, premium, coverage], {gas: 100000})
      console.log(`Policy ${policyId} created for flight ${flightId} with premium ${premium} and coverage ${coverage}`)
    }

    /**
     * Buy a new flight insurance policy
     * @param passengerName - Name of the passenger
     * @param flightId - Id of the flight for which passengers buys the policy
     */
    async buyPolicy(passengerName: string, flightId: number) {
      console.log(`- ${passengerName} buying policy for ${flightId}`)
      const contract = this.getPassengerName(passengerName)
      await contract.write.buyPolicy([flightId])
    }

    /**
     * File a claim for flight disruption
     * @param passengerName - Name of the passenger that has the policy
     * @param flightId - Flight number with disruption
     */
    async claimPayout(passengerName: string, policyId: number) {
      console.log(`- ${passengerName} filing claim for ${policyId}`)
      const contract = this.getPassengerName(passengerName)
      await contract.write.claimPayout([policyId])
    }

    /**
     * Process the insurance claim
     * @param passengerName - Name of the provider 
     * @param flightId - Id of the policy to be resolved
     * @param isResolved - whether policy has been resolved or not
     */
    async resolvePolicy(passengerName: string, flightId: number, isResolved: boolean) {
      console.log(`- Resolving claim for flight ${flightId} (status: ${isResolved})`)
      const contract = this.getPassengerName(passengerName)
      await contract.write.resolvePolicy([flightId, isResolved])  
    }

    /**
     * Allow providers to claim their coverage back 
     * @param providerName - Name of the provider/insurer
     * @param policyId - Id of the policy to be resolved
     */
    async claimCoverageBack(providerName: string, policyId: number) {
      console.log(`- ${providerName} claiming their coverage back for ${policyId}`)
      const contract = this.getProviderName(providerName)
      const status = await contract.write.claimCoverageBack([policyId])
      console.log(`Policy status: ${status}`)
    }
  }
  