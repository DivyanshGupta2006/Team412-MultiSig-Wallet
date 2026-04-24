# Multi-Signature Wallet

## Project Overview

This project is developed as part of the course **CS218 – Programmable and Interoperable Blockchain**, instructed by **Mrs. Subhra Mazumdar**.

The objective of this project is to design and implement a **Multi-Signature Wallet (MultiSig)** smart contract using Solidity and the Foundry framework, accompanied by a highly polished, modern Web3 React frontend.

The wallet enforces an **M-of-N approval mechanism**, meaning a transaction can only be executed after receiving a minimum number of approvals from registered owners.

This improves:
- Security (no single point of failure)
- Decentralized control of funds
- Protection against unauthorized transactions

---

## Team Members (412)

| Name | Roll Number |
|------|------------|
| Harsh Mahajan | 240001034 |
| Akarsh J | 240002007 |
| Hardik Hazari | 240003032 |
| Darsh Chaudhary | 240004014 |
| Shashvat Sharma | 240005043 |
| Aayush Sharma | 240041001 |
| Divyansh Gupta | 240041015 |

---

## Tech Stack

**Smart Contract Backend:**
- Solidity
- Foundry (Build, Testing, Gas Optimization)
- OpenZeppelin v5.6.1 (Security Standards)

**Web3 Frontend:**
- React 18 & Vite
- Ethers.js v6 (Blockchain Interaction)
- Vanilla CSS (Antigravity Glassmorphism UI)
- MetaMask (Wallet Authentication)

---

## Core Features

- **Decentralized Consensus**: Multiple wallet owners (set at deployment) with an M-of-N quorum required for execution.
- **Transaction Proposals**: Owners can submit transactions with target addresses, ETH values, and descriptive comments.
- **Approval Lifecycle**: Signers can approve or revoke their approvals before the threshold is met.
- **Premium User Interface**: Features a dynamic "Cyber-Aurora" aesthetic, mesh gradients, frosted glassmorphism, and responsive activity charting.
- **Role-Based Access**: The dashboard strictly verifies the connected MetaMask wallet; non-owners are blocked from the application.

---

## Security Features

- **Reentrancy Protection** using OpenZeppelin `ReentrancyGuard`
- **Checks-Effects-Interactions (CEI) Pattern**
- **Execution Flag (`executed`) set before external calls**
- **Custom Errors** → Gas-efficient reverts
- **Input Validation**
  - No zero address
  - No duplicate owners
  - Valid quorum

---

## Project Structure

```
├── src/
│   └── MultiSigWallet.sol       # Core Smart Contract
├── test/
│   └── MultiSigWallet.t.sol     # Foundry Tests
├── script/
│   └── Deploy.s.sol             # Deployment Script
├── frontend/
│   ├── src/
│   │   ├── components/          # React UI Components
│   │   ├── utils/contract.js    # Ethers.js ABI mapping
│   │   ├── App.jsx              # App state & routing
│   │   └── index.css            # Advanced UI styling
│   └── package.json             # React dependencies
├── deploy.sh                    # Automated deployment helper
└── README.md
```

---

# Installation & Usage Guide

## Prerequisites

- Git
- Foundry (forge, cast, anvil)
- Node.js (v18+)
- MetaMask Browser Extension

---

## 1. Smart Contract Setup

Clone the repository and install Foundry dependencies:

```bash
git clone <your-repo-link>
cd Team412-MultiSig-Wallet
forge install
```

### Build & Test

```bash
forge build
forge test -vvv
```

### Deployment

We have included a `deploy.sh` script to make deployment to Sepolia (or local Anvil) seamless. 

1. Create a `.env` file in the root directory:
```env
SEPOLIA_RPC_URL="your_alchemy_or_infura_url"
PRIVATE_KEY="your_wallet_private_key"
ETHERSCAN_API_KEY="your_etherscan_key_for_verification"
```

2. Run the deployment script:
```bash
# To deploy to local Anvil network
./deploy.sh local

# To deploy to Sepolia testnet
./deploy.sh sepolia
```

---

## 2. Frontend Setup

Once the contract is deployed, copy the deployed contract address from the terminal output.

1. Navigate to the frontend directory:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install
```

3. Update the Contract Address:
Open `frontend/src/utils/contract.js` and paste your newly deployed address:
```javascript
export const CONTRACT_ADDRESS = "0xYourDeployedAddressHere";
```

4. Start the Development Server:
```bash
npm run dev
```

5. Open your browser to `http://localhost:5173`. Connect your MetaMask wallet (ensure you are on the Sepolia network and using an owner account) to access the dashboard!

---

## License

MIT
