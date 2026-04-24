# Multi-Signature Wallet

> **CS218 – Programmable and Interoperable Blockchain** | Instructed by **Mrs. Subhra Mazumdar**

An M-of-N on-chain Multi-Signature Wallet built with Solidity and Foundry, featuring a premium Web3 React frontend. A transaction can only be executed after receiving a configurable minimum number of approvals from registered owners — enforced entirely in immutable smart contract code.

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
- Solidity `^0.8.24`
- Foundry (forge build, forge test, anvil)
- OpenZeppelin v5.6.1 (`ReentrancyGuard`)

**Web3 Frontend:**
- React 18 & Vite
- Ethers.js v6 (Blockchain Interaction)
- Vanilla CSS (Cyber-Aurora Glassmorphism UI)
- MetaMask (Wallet Authentication)

---

## Core Features

- **Decentralized Consensus**: Multiple wallet owners (set at deployment) with an M-of-N quorum required for execution.
- **Transaction Proposals**: Owners can submit transactions with target addresses, ETH values, calldata payloads, and human-readable descriptions.
- **Approval Lifecycle**: Signers can approve **or revoke** their approvals at any point before the threshold is met and the transaction is executed.
- **Premium User Interface**: Features a dynamic "Cyber-Aurora" aesthetic, mesh gradients, frosted glassmorphism, and a responsive activity chart.
- **Role-Based Access**: The dashboard strictly verifies the connected MetaMask wallet on-chain via `isOwner()`; non-owners are blocked from all write actions.
- **ETH Deposits**: Anyone can fund the wallet via plain ETH transfers — a `Deposit` event is emitted for full on-chain auditability.

---

## Transaction Lifecycle

Every transaction moves through a strict, on-chain enforced lifecycle:

```
  [Owner] ──submitTransaction()──► [PENDING] ──approveTransaction() × M──► [APPROVED]
                                        │                                         │
                                   revokeApproval()                     executeTransaction()
                                   (drops back)                                  │
                                                                           [EXECUTED ✓]
```

1. **Propose** — Any owner calls `submitTransaction(to, value, data, description)`. A new `Transaction` struct is pushed to the `transactions[]` array and assigned a sequential `txId`.
2. **Approve** — Owners independently call `approveTransaction(txId)`. Each approval is idempotent per owner (duplicate votes revert). The `approvalCount` increments in storage.
3. **Revoke** *(optional)* — Any approving owner may call `revokeApproval(txId)` before execution to withdraw their vote. The count decrements and their approval mapping resets to `false`.
4. **Execute** — Once `approvalCount >= requiredApprovals`, any owner calls `executeTransaction(txId)`. The contract marks it executed, then dispatches the low-level `.call{}(data)`. If the call fails, the entire transaction reverts — the `executed` flag rolls back too.

> A transaction can only ever transition to EXECUTED once. All subsequent attempts revert with `TxAlreadyExecuted`.

---

## Design Decisions

| Decision | Rationale |
|---|---|
| **Separate `submit` and `approve`** | Prevents the proposer from auto-approving — maintains fairness; encourages independent review before signing |
| **Array `owners[]` + Mapping `isOwner`** | Array enables frontend enumeration via `getOwners()`; mapping enables O(1) on-chain ownership checks without looping |
| **`txId` as array index** | Simple, gas-efficient — no extra mapping needed; sequential IDs are predictable and easy to reference |
| **Store `description` on-chain** | Adds human-readable context to each proposal visible to all owners and on Etherscan, improving governance transparency |
| **Low-level `.call{}(data)` for execution** | Supports both plain ETH sends and arbitrary calldata (e.g., calling functions on DeFi protocols), making the wallet a general-purpose multisig |
| **OpenZeppelin `ReentrancyGuard` over manual lock** | Industry-standard, audited implementation — reduces surface area for implementation bugs in the lock mechanism |
| **Custom errors over `require()` strings** | ~3× gas saving per revert; exact error selectors are machine-readable for better tooling and frontend UX |
| **`external` instead of `public`** | All user-facing functions use `external` — cheaper because arguments are read directly from calldata without copying to memory |
| **`receive()` with event** | Allows the wallet to be funded by anyone (not just owners) while maintaining a full on-chain deposit audit trail via `Deposit` event |

---

## Real-World Relevance

Multi-signature wallets are a foundational primitive in production blockchain infrastructure:

- **Gnosis Safe** — The most widely deployed multisig; secures $100B+ in assets for DAOs, protocols, and institutions. Our contract implements the same core M-of-N model.
- **DAO Treasuries** — Protocols like Uniswap, Aave, and Compound use multisigs to gate protocol upgrades and treasury spending — preventing unilateral admin abuse.
- **DeFi Protocol Admin Keys** — Ownership keys for upgradeable contracts are held in multisigs so no single developer can drain or rug a protocol.
- **Exchange Cold Wallets** — Custodians use N-of-M signing schemes for cold storage to require physical quorum among key holders before any withdrawal.
- **This Project** replicates the core trust model: no single owner can move funds — consensus is required and enforced cryptographically.

---

## Security Architecture

| Protection | Implementation |
|---|---|
| Reentrancy | OpenZeppelin `ReentrancyGuard` (`nonReentrant` on `executeTransaction`) |
| CEI Pattern | `executed = true` set **before** the external `.call{}()` |
| Custom Errors | 10 typed errors — `NotOwner`, `TxAlreadyApproved`, `InsufficientApprovals`, etc. (~3× cheaper than string reverts) |
| Duplicate Approvals | `mapping(uint256 => mapping(address => bool)) isApproved` + `notApproved` modifier |
| Double Execution | `bool executed` flag + `notExecuted` modifier on `approveTransaction`, `executeTransaction`, `revokeApproval` |
| Owner Validation | Zero-address check, duplicate check, and quorum bounds validated in constructor |
| Access Control | `onlyOwner` modifier on every state-changing function |

### Security Flow in `executeTransaction`

```solidity
// 1. CHECK — threshold enforced
if (txn.approvalCount < _requiredApprovals) revert InsufficientApprovals();

// 2. EFFECT — state updated BEFORE external call (CEI)
txn.executed = true;

// 3. INTERACT — low-level call, revert on failure
(bool success, ) = txn.to.call{value: txn.value}(txn.data);
if (!success) revert TxFailed();
```

---

## Attack Vectors & Mitigations

| Attack | Vector | Mitigation |
|---|---|---|
| **Reentrancy** | Malicious `_to` contract calls back into `executeTransaction` during `.call{}()` | `nonReentrant` (OZ) + CEI: `executed = true` before external call — re-entrant call hits `TxAlreadyExecuted` |
| **Unauthorized Execution** | Non-owner tries to execute a fully-approved transaction | `onlyOwner` modifier on `executeTransaction` reverts before any state change |
| **Double Execution** | Owner calls `executeTransaction` twice on same txId | `notExecuted` modifier reads `executed` flag — second call reverts with `TxAlreadyExecuted` |
| **Vote Stuffing** | Owner tries to approve the same tx multiple times to inflate count | `notApproved` modifier checks `isApproved[txId][msg.sender]` — second vote reverts with `TxAlreadyApproved` |
| **Threshold Bypass** | Owner tries to execute before reaching quorum | `approvalCount < requiredApprovals` check reverts with `InsufficientApprovals` |
| **Griefing via Malicious Receiver** | `_to` address is a contract that always reverts | `(bool success, ) = ...call{}()` captures the failure; `revert TxFailed()` propagates cleanly — state rolled back |
| **Bad Deployment Parameters** | Deploy with zero threshold, `M > N`, zero-address, or duplicate owner | Constructor validates all four conditions and reverts before any state is written |
| **Approve-After-Execute** | Owner tries to approve a completed tx (inflating count for logging) | `notExecuted` modifier on `approveTransaction` prevents state changes on executed transactions |

---

## Gas Optimizations

The contract applies several deliberate, commented optimizations:

| Optimization | Where Applied | Saving |
|---|---|---|
| `external` over `public` | All externally-called functions | Avoids ABI re-encoding for internal calls |
| `calldata` over `memory` | `submitTransaction` params (`_data`, `_description`) | Avoids copying args from calldata to memory |
| `unchecked { ++i; }` loop | Constructor owner loop | Bounded by `ownerCount`, safe to skip overflow check |
| `unchecked { txn.approvalCount += 1; }` | `approveTransaction` | Bounded by number of owners |
| `unchecked { txn.approvalCount -= 1; }` | `revokeApproval` | Guarded by `TxNotApproved` check above |
| Cached array length | `uint256 ownerCount = _owners.length` | Saves repeated SLOAD in loop condition |
| Cached storage read | `uint256 _requiredApprovals = requiredApprovals` | Saves one `SLOAD` in `executeTransaction` |
| `storage` pointer | `Transaction storage txn = transactions[_txId]` | No struct copy to memory |
| O(1) owner check | `mapping(address => bool) isOwner` | Avoids O(N) loop over `owners[]` array |

---

## Smart Contract API

**Contract:** `MultiSigWallet` | **Solidity:** `^0.8.24` | **License:** MIT

### Write Functions

| Function | Access | Description |
|---|---|---|
| `submitTransaction(address _to, uint256 _value, bytes calldata _data, string calldata _description)` | `onlyOwner` | Proposes a new transaction; returns `txId` |
| `approveTransaction(uint256 _txId)` | `onlyOwner` | Casts one approval vote for a pending transaction |
| `executeTransaction(uint256 _txId)` | `onlyOwner` | Executes a transaction once approval threshold is met |
| `revokeApproval(uint256 _txId)` | `onlyOwner` | Revokes a previously cast approval (before execution) |

### View Functions

| Function | Returns | Description |
|---|---|---|
| `getOwners()` | `address[] memory` | Full list of registered owner addresses |
| `getTransactionCount()` | `uint256` | Total number of submitted transactions |
| `getTransaction(uint256 _txId)` | `(to, value, data, description, executed, approvalCount)` | Full details of a transaction by ID |
| `isOwner(address)` | `bool` | Whether an address is a registered owner |
| `isApproved(uint256 txId, address owner)` | `bool` | Whether an owner has approved a specific transaction |
| `requiredApprovals()` | `uint256` | The M in M-of-N (approval threshold) |

### Events

| Event | Emitted When |
|---|---|
| `Deposit(address sender, uint256 amount, uint256 balance)` | ETH received via `receive()` |
| `SubmitTransaction(address owner, uint256 txId, address to, uint256 value, bytes data, string description)` | New transaction proposed |
| `ApproveTransaction(address owner, uint256 txId)` | An owner approves a transaction |
| `RevokeApproval(address owner, uint256 txId)` | An owner revokes their approval |
| `ExecuteTransaction(address owner, uint256 txId)` | Transaction successfully executed |

### Custom Errors

```solidity
error NotOwner();               // Caller is not a registered owner
error InvalidOwner();           // Zero-address or empty owners array
error OwnerNotUnique();         // Duplicate owner address in constructor
error InvalidRequiredApprovals(); // Threshold is 0 or exceeds owner count
error TxDoesNotExist();         // txId >= transactions.length
error TxAlreadyExecuted();      // Transaction was already executed
error TxAlreadyApproved();      // Caller already approved this tx
error TxNotApproved();          // Caller has not approved (for revoke)
error InsufficientApprovals();  // approvalCount < requiredApprovals
error TxFailed();               // External call returned false
```

---

## Frontend Architecture

The frontend is built as a **single-page React application** with a clean component hierarchy and real-time on-chain state synchronization.

### Component Hierarchy

```
App.jsx                        ← Root: wallet connection, signer, contract instance
├── Login.jsx                  ← MetaMask connect flow + on-chain owner verification
└── Dashboard.jsx              ← Fetches all contract state; layout orchestration
    ├── [stats bar]            ← Vault TVL / Consensus threshold / Event count
    ├── ActivityChart.jsx      ← Visual chart of transaction activity over time
    ├── OwnersList.jsx         ← Lists all registered signers; highlights connected wallet
    ├── SubmitTransaction.jsx  ← Form: propose new tx (owners only)
    └── TransactionList.jsx    ← Per-tx cards: Approve / Revoke / Execute actions
```

### Key Frontend Patterns

- **On-chain Owner Gate**: After MetaMask connects, `multisigContract.isOwner(account)` is called before rendering the dashboard. Non-owners see an "ACCESS DENIED" screen — this is enforced both on the frontend and at the contract level.
- **Parallel Data Fetching**: `Dashboard.jsx` uses `Promise.all([getBalance, getOwners, requiredApprovals, getTransactionCount])` — fetches 4 chain reads concurrently to minimize load time.
- **Per-User Approval Status**: For each transaction, `contract.isApproved(txId, account)` is called to show the connected owner whether they've already voted — prevents duplicate-approval attempts from the UI.
- **Event Listener Hygiene**: `accountsChanged` and `chainChanged` listeners are registered on `window.ethereum` and cleaned up in the `useEffect` return — prevents memory leaks and stale state on wallet/network switch.
- **Ethers.js v6**: Uses `ethers.BrowserProvider` + `getSigner()` — correct for Ethers v6 (replaces v5's `Web3Provider`).

---

## Testing

**Framework:** Foundry (`forge test`) | **Test file:** `test/MultiSigWallet.t.sol` | **30 test cases**

### Test Categories

| Category | Tests | What's Covered |
|---|---|---|
| Constructor | 5 | Empty owners, zero address, duplicate owner, invalid quorum (0 and > N) |
| Access Control | 4 | Non-owner blocked from all 4 write functions |
| Submit Transaction | 2 | Correct struct storage, event emission with description |
| Approve Transaction | 5 | State update, event, non-existent tx, already-executed, double-approval |
| Execute Transaction | 6 | ETH transfer, calldata execution, event, non-existent, double-execute, insufficient approvals |
| Revoke Approval | 4 | Count decrement, event, revert on executed tx, revert when not approved |
| ETH Deposit | 1 | `receive()` accepts ETH, emits `Deposit` with correct `balance` |
| End-to-End | 1 | Full submit → 2× approve → execute flow with state assertions |

### Run Tests

```bash
# Run all tests with verbose output
forge test -vvv

# Run a specific test
forge test --match-test test_executeTransaction_transfersEth -vvv

# Show gas report
forge test --gas-report
```

### Example Test: Full Happy Path

```solidity
function test_fullHappyPath_endToEnd() public {
    bytes memory data = abi.encodeWithSelector(MockTarget.setValue.selector, 777);
    vm.prank(owner1);
    uint256 txId = wallet.submitTransaction(address(target), 1 ether, data, "e2e: set 777 with 1 eth");

    vm.prank(owner1); wallet.approveTransaction(txId);
    vm.prank(owner2); wallet.approveTransaction(txId);
    vm.prank(owner3); wallet.executeTransaction(txId);

    assertEq(target.value(), 777);
    assertEq(target.lastMsgValue(), 1 ether);
    (, , , , bool executed, uint256 approvalCount) = wallet.getTransaction(txId);
    assertTrue(executed);
    assertEq(approvalCount, 2);
}
```

### All 30 Test Names

```
Constructor:
  test_constructor_setsStateCorrectly
  test_constructor_revertsOnEmptyOwners
  test_constructor_revertsOnZeroAddress
  test_constructor_revertsOnDuplicateOwner
  test_constructor_revertsOnInvalidRequiredApprovals

Access Control:
  test_submitTransaction_revertsForNonOwner
  test_approveTransaction_revertsForNonOwner
  test_executeTransaction_revertsForNonOwner
  test_revokeApproval_revertsForNonOwner

Submit Transaction:
  test_submitTransaction_storesCorrectFields
  test_submitTransaction_emitsEvent

Approve Transaction:
  test_approveTransaction_updatesState
  test_approveTransaction_emitsEvent
  test_approveTransaction_revertsOnNonExistentTx
  test_approveTransaction_revertsOnAlreadyExecutedTx
  test_approveTransaction_revertsOnDoubleApproval

Execute Transaction:
  test_executeTransaction_transfersEth
  test_executeTransaction_executesCalldata
  test_executeTransaction_emitsEvent
  test_executeTransaction_revertsOnNonExistentTx
  test_executeTransaction_revertsOnAlreadyExecuted
  test_executeTransaction_revertsOnInsufficientApprovals
  test_executeTransaction_revertsOnFailedCall

Revoke Approval:
  test_revokeApproval_decrementsCountAndUpdatesMapping
  test_revokeApproval_emitsEvent
  test_revokeApproval_revertsOnExecutedTx
  test_revokeApproval_revertsWhenNotApproved
  test_revokeApproval_blocksExecutionUntilReApproved

ETH Deposit:
  test_receive_acceptsEthAndEmitsDeposit

End-to-End:
  test_fullHappyPath_endToEnd
```

---

## Project Structure

```
├── src/
│   └── MultiSigWallet.sol       # Core Smart Contract (283 lines)
├── test/
│   └── MultiSigWallet.t.sol     # Foundry Tests (403 lines, 30 tests)
├── script/
│   └── deploy.s.sol             # Foundry Deployment Script
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Login.jsx            # MetaMask connect + owner-gate
│   │   │   ├── Dashboard.jsx        # Main dashboard layout & state
│   │   │   ├── SubmitTransaction.jsx # Propose new transaction form
│   │   │   ├── TransactionList.jsx  # Approve / Execute / Revoke UI
│   │   │   ├── OwnersList.jsx       # Display registered owners
│   │   │   └── ActivityChart.jsx    # Transaction activity visualization
│   │   ├── utils/contract.js    # Ethers.js Contract + ABI
│   │   ├── App.jsx              # App state & wallet connection
│   │   └── index.css            # Cyber-Aurora design system
│   └── package.json
├── deploy.sh                    # Automated deploy to Anvil / Sepolia
└── README.md
```

---

# Installation & Usage Guide

## Prerequisites

- Git
- Foundry (`forge`, `cast`, `anvil`) — [install](https://book.getfoundry.sh/getting-started/installation)
- Node.js (v18+)
- MetaMask Browser Extension

---

## 1. Smart Contract Setup

Clone the repository and install Foundry dependencies:

```bash
git clone https://github.com/DivyanshGupta2006/Team412-MultiSig-Wallet
cd Team412-MultiSig-Wallet
forge install
```

### Build & Test

```bash
forge build
forge test -vvv
forge test --gas-report   # View gas usage per function
```

### Deployment

We have included a `deploy.sh` script to make deployment to Sepolia (or local Anvil) seamless.

1. Create a `.env` file in the root directory:
```env
OWNER1="0xYourFirstOwnerAddress"
OWNER2="0xYourSecondOwnerAddress"
OWNER3="0xYourThirdOwnerAddress"
REQUIRED_APPROVALS=2
SEPOLIA_RPC_URL="your_alchemy_or_infura_url"
PRIVATE_KEY="your_wallet_private_key"
ETHERSCAN_API_KEY="your_etherscan_key_for_verification"
```

2. Run the deployment script:
```bash
# Deploy to local Anvil network
./deploy.sh local

# Deploy to Sepolia testnet (with Etherscan verification)
./deploy.sh sepolia
```

The script will output the deployed contract address. The Sepolia deployment is automatically verified on Etherscan via `--verify`.

**Live Deployment:** [`0x7cbC1b35f7Eb585929867CA400Dc0fE4F445DF04`](https://sepolia.etherscan.io/address/0x7cbC1b35f7Eb585929867CA400Dc0fE4F445DF04) on Sepolia Testnet.

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

3. Update the Contract Address in `frontend/src/utils/contract.js`:
```javascript
export const CONTRACT_ADDRESS = "0xYourDeployedAddressHere";
```

4. Start the Development Server:
```bash
npm run dev
```

5. Open your browser to `http://localhost:5173`. Connect your MetaMask wallet (ensure you are on the correct network and using a registered owner account) to access the dashboard.

> **Note:** Non-owner wallets are automatically blocked at the login screen with an "ACCESS DENIED" message — verified on-chain via `isOwner()`.

---

## Marking Criteria Coverage

| Criterion | Implementation |
|---|---|
| ✅ **Smart Contract Correctness** | All 5 core functions implemented; 30 tests passing; full M-of-N enforcement |
| ✅ **Security** | Reentrancy guard, CEI pattern, access control, input validation, 10 custom errors |
| ✅ **Gas Optimization** | 9 explicit optimizations: `external`, `calldata`, `unchecked`, cached SLOADs, O(1) mappings |
| ✅ **Testing Depth** | 30 unit tests across 8 categories; edge cases, attack simulations, full E2E test |
| ✅ **Frontend** | 6-component React app; MetaMask integration; on-chain owner gate; real-time state sync |
| ✅ **Deployment** | Live on Sepolia testnet; Etherscan source-verified; Anvil local support via `deploy.sh` |
| ✅ **Documentation** | Full API reference, lifecycle diagram, design decisions, attack vectors, install guide |
| ✅ **Real-World Relevance** | Mirrors Gnosis Safe model; applicable to DAOs, treasury management, DeFi admin keys |

---

## License

MIT
