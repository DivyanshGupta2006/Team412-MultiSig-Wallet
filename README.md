# Multi-Signature Wallet 

## Project Overview

This project is developed as part of the course **CS218 – Programmable and Interoperable Blockchain**, instructed by **Mrs. Subhra Mazumdar**.

The objective of this project is to design and implement a **Multi-Signature Wallet (MultiSig)** smart contract using Solidity and the Foundry framework. The system allows multiple owners to jointly control funds by enforcing an approval threshold mechanism.

Each transaction must be approved by at least **M out of N registered owners** before execution. This approach enhances security, enforces decentralized decision-making, and mitigates risks such as single point of failure or unauthorized fund transfers.

---

## Team Members (412)

| Name      | Roll Number |
| --------- | ----------- |
| Harsh Mahajan | 240001034 |
| Akarsh J | 240002007 |
| Hardik Hazari | 240003032  |
| Darsh Chaudhary  | 240004014 |
| Shashvat Sharma | 240005043 |
| Aayush Sharma | 240041001 |
| Divyansh Gupta | 240041015 |

---

## Tech Stack

* Solidity (Smart Contracts)
* Foundry (Testing, Build, Gas Report)
* MetaMask (Wallet Interaction)
* IPFS (for optional off-chain storage)

---

## Setup Instructions

### Prerequisites

* Git installed
* MetaMask browser extension
* Basic familiarity with terminal/command line

---

# Installation Guide

---

## 1. Linux

### Install Dependencies

```bash
sudo pacman -S git curl   # Arch / CachyOS
# OR
sudo apt update && sudo apt install git curl   # Ubuntu/Debian
```

### Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc   # or ~/.zshrc
foundryup
```

---

## 2. macOS

### Install Dependencies (via Homebrew)

```bash
brew install git curl
```

### Install Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
source ~/.zshrc
foundryup
```

---

## 3. Windows

### Option A (Recommended: WSL)

1. Install WSL:

```powershell
wsl --install
```

2. Open Ubuntu (WSL terminal), then run:

```bash
sudo apt update && sudo apt install git curl
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

---

### Option B (Native Windows - Not Recommended)

Use Git Bash or PowerShell:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

---

# Project Setup

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
forge test
```

---

### Generate Gas Report

```bash
forge test --gas-report
```

---

### Generate Coverage Report

```bash
forge coverage
```

---

### Deploy Contract (Example)

```bash
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

---

## Notes

* Replace `<RPC_URL>` with your network provider (e.g., Alchemy/Infura)
* Replace `<PRIVATE_KEY>` with your wallet private key (use `.env` for safety)
* Ensure MetaMask is connected to the correct network

---
