




### 1. Contract Deployment
deploy the contract using ```npx thirdweb deploy``` and set the USDC & USDT address.

```
// USDC ETH SEPOLA ->	0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238
// USDC ETH SEPOLA ->	0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0
```

### 2. Set Base URI
Set the initial server URL as the base URI

### 3. Burn  token
Burn token with Id = 0

### 4. Activate Sale
The owner can activate the sale, allowing public minting of the tokens.

### 5. Activate Allow List
The owner can activate an allow list (whitelist), restricting minting to only the addresses included in this list.

### 6. Populate Allow List
The owner adds addresses to the allow list, enabling them to mint tokens during the allow list-only phase.

### 7. Minting
Eligible users can mint tokens, either during the allow list phase or the public sale, using either ETH, USDC, or USDT for payment.
- **Mint with ETH**: Users can mint tokens by sending the correct amount of ETH to the contract.
- **Mint with USDC/USDT**: Users approve the contract to spend the required amount of USDC/USDT and then call the mint function.
Approve function should be called from the USDC/USDT contract 

