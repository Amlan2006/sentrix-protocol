# BSC Testnet Deployment Config

```text
Network: BSC Testnet
Chain ID: 97
Native currency: tBNB
Explorer: https://testnet.bscscan.com/
Foundry RPC endpoint: bsc_testnet
RPC env var: BSC_TESTNET_RPC_URL
```

## PancakeSwap V2

```text
Router:  0xD99D1c33F9fC3444f8101754aBC46c52416550D1
Factory: 0x6725F303b657a9451d8BA641348b6761A6CC7a17
WBNB:    0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
```

The Pancake router method is named `WETH()` in the V2 ABI, but it returns the WBNB token on BSC.
