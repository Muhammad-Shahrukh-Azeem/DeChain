import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { virtual_mainnet } from './tenderly.config';

export const config = getDefaultConfig({
  appName: 'RainbowKit App',
  projectId: 'YOUR_PROJECT_ID',
  chains: [
    virtual_mainnet,
  ],
  ssr: true,
});
