pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

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

    event Deposit(address indexed sender, uint256 amount, uint256 balance);

    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txId,
        address indexed to,
        uint256 value,
        bytes data,
        string description
    );
    
    event ApproveTransaction(address indexed owner, uint256 indexed txId);
    event RevokeApproval(address indexed owner, uint256 indexed txId);
    event ExecuteTransaction(address indexed owner, uint256 indexed txId);
   
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        string description;
        bool executed;
        uint256 approvalCount;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public requiredApprovals;
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public isApproved;
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) revert NotOwner();
        _;
    }

    modifier txExists(uint256 _txId) {
        if (_txId >= transactions.length) revert TxDoesNotExist();
        _;
    }

    modifier notExecuted(uint256 _txId) {
        if (transactions[_txId].executed) revert TxAlreadyExecuted();
        _;
    }

    modifier notApproved(uint256 _txId) {
        if (isApproved[_txId][msg.sender]) revert TxAlreadyApproved();
        _;
    }

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

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data,
        string memory _description
    ) public onlyOwner returns (uint256 txId) {
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

        txn.executed = true;

        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        if (!success) revert TxFailed();

        emit ExecuteTransaction(msg.sender, _txId);
    }

    function revokeApproval(
        uint256 _txId
    ) public onlyOwner txExists(_txId) notExecuted(_txId) {
        if (!isApproved[_txId][msg.sender]) revert TxNotApproved();

        Transaction storage txn = transactions[_txId];
        txn.approvalCount -= 1;
        isApproved[_txId][msg.sender] = false;

        emit RevokeApproval(msg.sender, _txId);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getTransaction(
        uint256 _txId
    )
        public
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
