# Multi-Signature Wallet 

## Project Overview

This project is developed as part of the course **CS218 – Programmable and Interoperable Blockchain**, instructed by **Mrs. Subhra Mazumdar**.

The objective of this project is to design and implement a **Multi-Signature Wallet (MultiSig)** smart contract using Solidity and the Foundry framework.

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

- Solidity (Smart Contracts)
- Foundry (Build, Testing, Gas Optimization)
- OpenZeppelin v5.6.1 (Security Standards)
- MetaMask (Wallet Interaction)
- IPFS (Optional Off-chain Storage)

---

## Core Features

- Multiple wallet owners (set at deployment)
- Transaction proposal system
- Approval-based execution (M-of-N quorum)
- Revocation of approvals before execution
- Secure execution using best practices

---

## Contract Overview

### `MultiSigWallet.sol`

The contract implements:

- **Immutable owner set**
- **Transaction lifecycle:**
  1. Submit
  2. Approve
  3. Execute
  4. Revoke (optional)

---

### Key Functions

| Function | Description |
|---|---|
| `submitTransaction(to, value, data)` | Propose a new transaction |
| `approveTransaction(txId)` | Approve a transaction |
| `executeTransaction(txId)` | Execute after quorum is reached |
| `revokeApproval(txId)` | Revoke approval before execution |
| `getOwners()` | Returns list of owners |
| `getTransaction(txId)` | Returns transaction details |
| `getTransactionCount()` | Returns total transactions |

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
├── src/
│ └── MultiSigWallet.sol
├── test/
│ └── MultiSigWallet.t.sol
├── script/
│ └── Deploy.s.sol
├── docs/
│ └── MultiSigWallet_Explained.md
├── lib/
│ ├── forge-std/
│ └── openzeppelin-contracts/
├── foundry.toml
└── README.md

---

# Installation Guide

---

## Prerequisites

- Git
- Foundry (forge, cast, anvil)
- MetaMask
- Basic CLI knowledge

---

## 1. Linux

```bash
sudo apt update && sudo apt install git curl
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

---

## 2. macOS

```bash
brew install git curl
curl -L https://foundry.paradigm.xyz | bash
source ~/.zshrc
foundryup
```

---

## 3. Windows (Recommended: WSL)

```powershell
wsl --install
```

Then inside WSL:

```bash
sudo apt update && sudo apt install git curl
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

---

## Project Setup

### Clone Repository

```bash
git clone <your-repo-link>
cd project-10-multisig-wallet
```

---

### Install Dependencies

```bash
forge install
```

---

### Build Contracts

```bash
forge build
```

---

### Run Tests

```bash
# Standard tests
forge test

# Verbose
forge test -vvv

# Gas report
forge test --gas-report

# Coverage
forge coverage
```

---

## Local Deployment (Anvil)

```bash
anvil &
forge script script/Deploy.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --broadcast --private-key <DEPLOYER_PRIVATE_KEY>
```

---

## Custom Deployment (Owners + Threshold)

```bash
OWNER1=0x... OWNER2=0x... OWNER3=0x... REQUIRED_APPROVALS=2 \
forge script script/Deploy.s.sol \
  --rpc-url <RPC_URL> \
  --broadcast --private-key <PRIVATE_KEY>
```

---

## Notes

- Replace `<RPC_URL>` with Alchemy/Infura endpoint
- Store private keys securely using `.env`
- Ensure MetaMask is connected to the correct network

---

## License

MIT
