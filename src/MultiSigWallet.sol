// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title MultiSigWallet
/// @notice An M-of-N multi-signature wallet that requires a minimum number of owner approvals before any transaction can be executed.
/// @dev Inherits OpenZeppelin's ReentrancyGuard to protect executeTransaction from reentrancy attacks.
contract MultiSigWallet is ReentrancyGuard {
    error NotOwner();
    error InvalidOwner();
    error OwnerNotUnique();
    error InvalidRequiredApprovals();
    error TxDoesNotExist();
    error TxAlreadyExecuted();
    error TxAlreadyApproved();
    error TxNotApproved();
    error InsufficientApprovals();
    error TxFailed();

    /// @notice Emitted when ETH is deposited into the wallet via the receive() function.
    /// @param sender The address that sent the ETH.
    /// @param amount The amount of ETH deposited (in wei).
    /// @param balance The new total balance of the wallet after the deposit.
    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    /// @notice Emitted when a new transaction is submitted by an owner.
    /// @param owner The owner who submitted the transaction.
    /// @param txId The ID assigned to the newly created transaction.
    /// @param to The target address of the transaction.
    /// @param value The amount of ETH (in wei) to send with the transaction.
    /// @param data The calldata to pass to the target address.
    /// @param description A human-readable description of the transaction purpose.
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txId,
        address indexed to,
        uint256 value,
        bytes data,
        string description
    );
    
    /// @notice Emitted when an owner approves a pending transaction.
    /// @param owner The owner who approved.
    /// @param txId The ID of the approved transaction.
    event ApproveTransaction(address indexed owner, uint256 indexed txId);

    /// @notice Emitted when an owner revokes their previous approval.
    /// @param owner The owner who revoked their approval.
    /// @param txId The ID of the transaction whose approval was revoked.
    event RevokeApproval(address indexed owner, uint256 indexed txId);

    /// @notice Emitted when a transaction is successfully executed.
    /// @param owner The owner who triggered the execution.
    /// @param txId The ID of the executed transaction.
    event ExecuteTransaction(address indexed owner, uint256 indexed txId);
   
    /// @notice Represents a proposed transaction stored in the wallet.
    /// @param to The target address to call.
    /// @param value The ETH value (in wei) to send.
    /// @param data The calldata payload for the external call.
    /// @param description A human-readable description of the transaction.
    /// @param executed Whether the transaction has been executed.
    /// @param approvalCount The number of owner approvals received so far.
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        string description;
        bool executed;
        uint256 approvalCount;
    }

    /// @notice Ordered list of wallet owner addresses.
    address[] public owners;

    /// @notice Mapping to quickly check if an address is a registered owner.
    mapping(address => bool) public isOwner;

    /// @notice The minimum number of approvals required to execute a transaction (M in M-of-N).
    uint256 public requiredApprovals;

    /// @notice Array of all submitted transactions (index = txId).
    Transaction[] public transactions;

    /// @notice Tracks whether a specific owner has approved a specific transaction.
    /// @dev isApproved[txId][ownerAddress] => bool
    mapping(uint256 => mapping(address => bool)) public isApproved;

    /// @notice Restricts function access to registered wallet owners only.
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    /// @notice Ensures the transaction ID refers to an existing transaction.
    /// @param _txId The transaction ID to validate.
    modifier txExists(uint256 _txId) {
        if (_txId >= transactions.length) revert TxDoesNotExist();
        _;
    }

    /// @notice Ensures the transaction has not already been executed.
    /// @param _txId The transaction ID to check.
    modifier notExecuted(uint256 _txId) {
        if (transactions[_txId].executed) revert TxAlreadyExecuted();
        _;
    }

    /// @notice Ensures the caller has not already approved the transaction.
    /// @param _txId The transaction ID to check.
    modifier notApproved(uint256 _txId) {
        if (isApproved[_txId][msg.sender]) revert TxAlreadyApproved();
        _;
    }

    /// @notice Deploys a new MultiSigWallet with the given owners and approval threshold.
    /// @param _owners Array of owner addresses (must be non-empty, no duplicates, no zero-address).
    /// @param _requiredApprovals Minimum approvals needed to execute a transaction (1 ≤ M ≤ N).
    constructor(address[] memory _owners, uint256 _requiredApprovals) {
        uint256 ownerCount = _owners.length; // Gas: cache array length
        if (ownerCount == 0) revert InvalidOwner();
        if (
            _requiredApprovals == 0 ||
            _requiredApprovals > ownerCount
        ) {
            revert InvalidRequiredApprovals();
        }

        for (uint256 i = 0; i < ownerCount;) {
            address owner = _owners[i];

            if (owner == address(0)) revert InvalidOwner();
            if (isOwner[owner]) revert OwnerNotUnique();

            isOwner[owner] = true;
            owners.push(owner);

            unchecked { ++i; } // Gas: safe because i < ownerCount is bounded
        }

        requiredApprovals = _requiredApprovals;
    }

    /// @notice Allows the wallet to receive ETH directly and emits a Deposit event.
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /// @notice Submits a new transaction proposal for other owners to approve.
    /// @param _to The target address for the transaction.
    /// @param _value The amount of ETH (in wei) to send.
    /// @param _data The calldata to include in the low-level call.
    /// @param _description A human-readable description of the transaction purpose.
    /// @return txId The index of the newly created transaction in the transactions array.
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data,
        string calldata _description
    ) external onlyOwner returns (uint256 txId) { // Gas: external + calldata avoids memory copy
        txId = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                description: _description,
                executed: false,
                approvalCount: 0
            })
        );

        emit SubmitTransaction(msg.sender, txId, _to, _value, _data, _description);
    }

    /// @notice Approves a pending transaction. Each owner can only approve once per transaction.
    /// @param _txId The ID of the transaction to approve.
    function approveTransaction(
        uint256 _txId
    )
        external // Gas: external is cheaper than public for non-internally-called functions
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
        notApproved(_txId)
    {
        Transaction storage txn = transactions[_txId];
        unchecked { txn.approvalCount += 1; } // Gas: cannot overflow — bounded by number of owners
        isApproved[_txId][msg.sender] = true;

        emit ApproveTransaction(msg.sender, _txId);
    }

    /// @notice Executes a transaction once it has received enough approvals.
    /// @dev Uses the Checks-Effects-Interactions (CEI) pattern: marks executed = true before the external call.
    ///      Protected by OpenZeppelin's nonReentrant modifier to prevent reentrancy attacks.
    /// @param _txId The ID of the transaction to execute.
    function executeTransaction(
        uint256 _txId
    )
        external // Gas: external is cheaper than public for non-internally-called functions
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
        nonReentrant
    {
        Transaction storage txn = transactions[_txId];
        uint256 _requiredApprovals = requiredApprovals; // Gas: cache SLOAD into memory

        if (txn.approvalCount < _requiredApprovals) {
            revert InsufficientApprovals();
        }

        txn.executed = true;

        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        if (!success) revert TxFailed();

        emit ExecuteTransaction(msg.sender, _txId);
    }

    /// @notice Revokes a previously given approval for a pending transaction.
    /// @param _txId The ID of the transaction to revoke approval from.
    function revokeApproval(
        uint256 _txId
    ) external onlyOwner txExists(_txId) notExecuted(_txId) { // Gas: external is cheaper
        if (!isApproved[_txId][msg.sender]) revert TxNotApproved();

        Transaction storage txn = transactions[_txId];
        unchecked { txn.approvalCount -= 1; } // Gas: cannot underflow — checked by TxNotApproved above
        isApproved[_txId][msg.sender] = false;

        emit RevokeApproval(msg.sender, _txId);
    }

    /// @notice Returns the complete list of wallet owner addresses.
    /// @return An array of all owner addresses.
    function getOwners() external view returns (address[] memory) { // Gas: external avoids ABI re-encoding
        return owners;
    }

    /// @notice Returns the total number of transactions that have been submitted.
    /// @return The length of the transactions array.
    function getTransactionCount() external view returns (uint256) { // Gas: external
        return transactions.length;
    }

    /// @notice Returns the full details of a transaction by its ID.
    /// @param _txId The ID of the transaction to query.
    /// @return to The target address.
    /// @return value The ETH value in wei.
    /// @return data The calldata payload.
    /// @return description The human-readable description.
    /// @return executed Whether the transaction has been executed.
    /// @return approvalCount The number of approvals received.
    function getTransaction(
        uint256 _txId
    )
        external // Gas: external
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            string memory description,
            bool executed,
            uint256 approvalCount
        )
    {
        Transaction storage txn = transactions[_txId];

        return (
            txn.to,
            txn.value,
            txn.data,
            txn.description,
            txn.executed,
            txn.approvalCount
        );
    }
}