# MultiSig Wallet

> A multi-signature wallet smart contract built with **Foundry** and **OpenZeppelin v5.6.1**.
> Requires M-of-N owner approvals before any transaction can be executed.

## Team

| Name | Roll Number |
|------|-------------|
| *Akarsh J* | *(Add roll number)* |
| *Aayush Sharma* | *(Add roll number)* |
| *Darsh Chaudhary* | *(Add roll number)* |
| *Divyansh Gupta* | *(Add roll number)* |
| *Hardik Hazari* | *(Add roll number)* |
| *Harsh Mahajan* | *(Add roll number)* |

---

## Setup & Installation

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (forge, cast, anvil)
- Git

### Clone & Install

```bash
git clone <repository-url>
cd Team412-MultiSig-Wallet
forge install
```

### Compile

```bash
forge build
```

### Run Tests

```bash
# Run all tests with verbose output
forge test -vvv

# Run with gas report
forge test --gas-report

# Run coverage report
forge coverage
```

### Deploy

```bash
# Local deployment (Anvil)
anvil &
forge script script/deploy.s.sol:DeployMultiSigWallet \
    --rpc-url http://127.0.0.1:8545 \
    --broadcast --private-key <DEPLOYER_PRIVATE_KEY>

# Custom owners & threshold
OWNER1=0x... OWNER2=0x... OWNER3=0x... REQUIRED_APPROVALS=2 \
    forge script script/deploy.s.sol:DeployMultiSigWallet \
    --rpc-url <RPC_URL> --broadcast --private-key <DEPLOYER_KEY>
```

---

## Contract Overview

### `MultiSigWallet.sol`

A multi-signature wallet where:
- A set of **owners** is defined at deployment (immutable).
- Any owner can **submit** a transaction proposal.
- Owners **approve** pending transactions.
- Once the **quorum** (M-of-N) is reached, any owner can **execute** the transaction.
- Owners can **revoke** their approval before execution.

### Key Functions

| Function | Description |
|---|---|
| `submitTransaction(to, value, data)` | Propose a new transaction; returns `txId` |
| `approveTransaction(txId)` | Add your approval to a pending transaction |
| `executeTransaction(txId)` | Execute a transaction once quorum is met |
| `revokeApproval(txId)` | Revoke a previously given approval |
| `getOwners()` | View all wallet owners |
| `getTransaction(txId)` | View details of a specific transaction |
| `getTransactionCount()` | View total number of submitted transactions |

### Security Features

- **ReentrancyGuard** (OpenZeppelin) on `executeTransaction()`
- **Checks-Effects-Interactions** pattern — `executed` flag set before external call
- **Custom errors** for gas-efficient reverts
- **Input validation** — zero-address, duplicates, invalid quorum

---

## Project Structure

```
├── src/
│   └── MultiSigWallet.sol      # Main contract
├── test/
│   └── MultiSigWallet.t.sol    # Comprehensive test suite
├── script/
│   └── deploy.s.sol            # Deployment script
├── docs/
│   └── MultiSigWallet_Explained.md  # Detailed code explanation
├── lib/
│   ├── forge-std/               # Foundry standard library
│   └── openzeppelin-contracts/  # OpenZeppelin v5.6.1
├── foundry.toml                 # Foundry configuration
└── README.md                    # This file
```

---

## License

MIT