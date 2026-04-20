// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title MultiSigWallet
 * @author Team412
 * @notice A multi-signature wallet requiring M-of-N owner approvals
 *         before any transaction can be executed.
 * @dev Uses OpenZeppelin ReentrancyGuard on executeTransaction().
 *      Follows Checks-Effects-Interactions (CEI) pattern throughout.
 *      All other logic is written from scratch (no Ownable, etc.).
 */
contract MultiSigWallet is ReentrancyGuard {
    // ──────────────────────────────────────────────
    //  Custom Errors (gas-efficient)
    // ──────────────────────────────────────────────

    /// @notice Thrown when a non-owner calls a restricted function.
    error NotOwner();

    /// @notice Thrown when address(0) is passed as an owner or owners array is empty.
    error InvalidOwner();

    /// @notice Thrown when a duplicate owner address is detected in the constructor.
    error OwnerNotUnique();

    /// @notice Thrown when requiredApprovals is 0 or exceeds the number of owners.
    error InvalidRequiredApprovals();

    /// @notice Thrown when a transaction index is out of bounds.
    error TxDoesNotExist();

    /// @notice Thrown when acting on an already-executed transaction.
    error TxAlreadyExecuted();

    /// @notice Thrown when an owner tries to approve a transaction they already approved.
    error TxAlreadyApproved();

    /// @notice Thrown when an owner tries to revoke an approval they haven't given.
    error TxNotApproved();

    /// @notice Thrown when executing a transaction without enough approvals.
    error InsufficientApprovals();

    /// @notice Thrown when the low-level call in executeTransaction() fails.
    error TxFailed();

    // ──────────────────────────────────────────────
    //  Events
    // ──────────────────────────────────────────────

    /// @notice Emitted when the contract receives Ether via receive().
    /// @param sender The address that sent the Ether.
    /// @param amount The amount of Ether received (in wei).
    /// @param balance The new total balance of the contract.
    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    /// @notice Emitted when an owner submits a new transaction proposal.
    /// @param owner The owner who submitted the transaction.
    /// @param txId The index of the newly created transaction.
    /// @param to The target address of the transaction.
    /// @param value The Ether value (in wei) to send.
    /// @param data The calldata to include in the call.
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txId,
        address indexed to,
        uint256 value,
        bytes data
    );

    /// @notice Emitted when an owner approves a pending transaction.
    /// @param owner The owner who approved.
    /// @param txId The index of the approved transaction.
    event ApproveTransaction(address indexed owner, uint256 indexed txId);

    /// @notice Emitted when an owner revokes their approval.
    /// @param owner The owner who revoked.
    /// @param txId The index of the transaction.
    event RevokeApproval(address indexed owner, uint256 indexed txId);

    /// @notice Emitted when a transaction is successfully executed.
    /// @param owner The owner who triggered execution.
    /// @param txId The index of the executed transaction.
    event ExecuteTransaction(address indexed owner, uint256 indexed txId);

    // ──────────────────────────────────────────────
    //  Data Structures
    // ──────────────────────────────────────────────

    /// @notice Represents a single proposed transaction.
    /// @param to Target address of the call.
    /// @param value Amount of Ether (in wei) to send.
    /// @param data Calldata bytes for the call.
    /// @param executed Whether this transaction has been executed.
    /// @param approvalCount Number of owners who have approved.
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 approvalCount;
    }

    // ──────────────────────────────────────────────
    //  State Variables
    // ──────────────────────────────────────────────

    /// @notice Ordered list of wallet owners set at deployment.
    address[] public owners;

    /// @notice O(1) lookup to verify if an address is an owner.
    mapping(address => bool) public isOwner;

    /// @notice The minimum number of approvals (M) needed to execute a transaction.
    uint256 public requiredApprovals;

    /// @notice Append-only array of all submitted transactions.
    Transaction[] public transactions;

    /// @notice Tracks which owner has approved which transaction.
    /// @dev txId => ownerAddress => hasApproved
    mapping(uint256 => mapping(address => bool)) public isApproved;

    // ──────────────────────────────────────────────
    //  Modifiers
    // ──────────────────────────────────────────────

    /// @dev Restricts function access to wallet owners only.
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    /// @dev Validates that the transaction index exists.
    modifier txExists(uint256 _txId) {
        if (_txId >= transactions.length) revert TxDoesNotExist();
        _;
    }

    /// @dev Validates that the transaction has not been executed.
    modifier notExecuted(uint256 _txId) {
        if (transactions[_txId].executed) revert TxAlreadyExecuted();
        _;
    }

    /// @dev Validates that the caller has not already approved the transaction.
    modifier notApproved(uint256 _txId) {
        if (isApproved[_txId][msg.sender]) revert TxAlreadyApproved();
        _;
    }

    // ──────────────────────────────────────────────
    //  Constructor
    // ──────────────────────────────────────────────

    /**
     * @notice Deploys the MultiSigWallet with a fixed set of owners and an approval threshold.
     * @param _owners Array of owner addresses. Must be non-empty, with no duplicates or zero addresses.
     * @param _requiredApprovals The minimum number of approvals (M) to execute a transaction.
     *        Must satisfy: 0 < _requiredApprovals <= _owners.length.
     */
    constructor(address[] memory _owners, uint256 _requiredApprovals) {
        if (_owners.length == 0) revert InvalidOwner();
        if (
            _requiredApprovals == 0 ||
            _requiredApprovals > _owners.length
        ) {
            revert InvalidRequiredApprovals();
        }

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            if (owner == address(0)) revert InvalidOwner();
            if (isOwner[owner]) revert OwnerNotUnique();

            isOwner[owner] = true;
            owners.push(owner);
        }

        requiredApprovals = _requiredApprovals;
    }

    // ──────────────────────────────────────────────
    //  Receive Ether
    // ──────────────────────────────────────────────

    /// @notice Allows the contract to accept plain Ether transfers.
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // ──────────────────────────────────────────────
    //  Transaction Lifecycle
    // ──────────────────────────────────────────────

    /**
     * @notice Submits a new transaction proposal for owner approval.
     * @param _to Target address of the transaction.
     * @param _value Amount of Ether (in wei) to send with the transaction.
     * @param _data Calldata to include in the low-level call.
     * @return txId The index of the newly created transaction.
     */
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlyOwner returns (uint256 txId) {
        txId = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                approvalCount: 0
            })
        );

        emit SubmitTransaction(msg.sender, txId, _to, _value, _data);
    }

    /**
     * @notice Approves a pending transaction. Each owner may approve only once.
     * @param _txId Index of the transaction to approve.
     */
    function approveTransaction(
        uint256 _txId
    )
        public
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
        notApproved(_txId)
    {
        Transaction storage txn = transactions[_txId];
        txn.approvalCount += 1;
        isApproved[_txId][msg.sender] = true;

        emit ApproveTransaction(msg.sender, _txId);
    }

    /**
     * @notice Executes a transaction after it has received the required number of approvals.
     * @dev Protected by OpenZeppelin's nonReentrant modifier. Follows CEI pattern:
     *      the `executed` flag is set BEFORE the external call.
     * @param _txId Index of the transaction to execute.
     */
    function executeTransaction(
        uint256 _txId
    )
        public
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
        nonReentrant
    {
        Transaction storage txn = transactions[_txId];

        if (txn.approvalCount < requiredApprovals) {
            revert InsufficientApprovals();
        }

        // EFFECTS — mark executed before external call (CEI pattern)
        txn.executed = true;

        // INTERACTIONS — low-level call with calldata
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        if (!success) revert TxFailed();

        emit ExecuteTransaction(msg.sender, _txId);
    }

    /**
     * @notice Revokes a previously given approval on a pending transaction.
     * @param _txId Index of the transaction to revoke approval for.
     */
    function revokeApproval(
        uint256 _txId
    ) public onlyOwner txExists(_txId) notExecuted(_txId) {
        if (!isApproved[_txId][msg.sender]) revert TxNotApproved();

        Transaction storage txn = transactions[_txId];
        txn.approvalCount -= 1;
        isApproved[_txId][msg.sender] = false;

        emit RevokeApproval(msg.sender, _txId);
    }

    // ──────────────────────────────────────────────
    //  View / Helper Functions
    // ──────────────────────────────────────────────

    /**
     * @notice Returns the complete list of wallet owners.
     * @return Array of owner addresses.
     */
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    /**
     * @notice Returns the total number of submitted transactions.
     * @return The length of the transactions array.
     */
    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    /**
     * @notice Returns the full details of a specific transaction.
     * @param _txId Index of the transaction to query.
     * @return to Target address.
     * @return value Ether value in wei.
     * @return data Calldata bytes.
     * @return executed Whether the transaction has been executed.
     * @return approvalCount Current number of approvals.
     */
    function getTransaction(
        uint256 _txId
    )
        public
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 approvalCount
        )
    {
        Transaction storage txn = transactions[_txId];

        return (
            txn.to,
            txn.value,
            txn.data,
            txn.executed,
            txn.approvalCount
        );
    }
}