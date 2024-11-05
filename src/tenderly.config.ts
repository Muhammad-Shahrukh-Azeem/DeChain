import { defineChain } from 'viem'

export const virtual_mainnet = defineChain({
  id: 1,
  name: 'Virtual Mainnet',
  nativeCurrency: { name: 'VETH', symbol: 'VETH', decimals: 18 },
  rpcUrls: {
    default: { http: ['https://virtual.mainnet.rpc.tenderly.co/cdbc3e91-7911-4cdf-968a-cac82f48125c'] }
  },
  blockExplorers: {
    default: {
      name: 'Tenderly Explorer',
      url: 'https://virtual.mainnet.rpc.tenderly.co/637fdce9-f5de-4130-977e-35b03d5b3277'
    }
  },
})