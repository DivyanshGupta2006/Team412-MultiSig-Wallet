import { ethers } from "ethers";

export const CONTRACT_ADDRESS = "0x7cbC1b35f7Eb585929867CA400Dc0fE4F445DF04"; // Deployed on Sepolia

export const CONTRACT_ABI = [
  "constructor(address[] _owners, uint256 _requiredApprovals)",
  "error InsufficientApprovals()",
  "error InvalidOwner()",
  "error InvalidRequiredApprovals()",
  "error NotOwner()",
  "error OwnerNotUnique()",
  "error TxAlreadyApproved()",
  "error TxAlreadyExecuted()",
  "error TxDoesNotExist()",
  "error TxFailed()",
  "error TxNotApproved()",
  "event ApproveTransaction(address indexed owner, uint256 indexed txId)",
  "event Deposit(address indexed sender, uint256 amount, uint256 balance)",
  "event ExecuteTransaction(address indexed owner, uint256 indexed txId)",
  "event RevokeApproval(address indexed owner, uint256 indexed txId)",
  "event SubmitTransaction(address indexed owner, uint256 indexed txId, address indexed to, uint256 value, bytes data, string description)",
  "function approveTransaction(uint256 _txId)",
  "function executeTransaction(uint256 _txId)",
  "function getOwners() view returns (address[])",
  "function getTransaction(uint256 _txId) view returns (address to, uint256 value, bytes data, string description, bool executed, uint256 approvalCount)",
  "function getTransactionCount() view returns (uint256)",
  "function isApproved(uint256, address) view returns (bool)",
  "function isOwner(address) view returns (bool)",
  "function owners(uint256) view returns (address)",
  "function requiredApprovals() view returns (uint256)",
  "function revokeApproval(uint256 _txId)",
  "function submitTransaction(address _to, uint256 _value, bytes _data, string _description) returns (uint256 txId)",
  "function transactions(uint256) view returns (address to, uint256 value, bytes data, string description, bool executed, uint256 approvalCount)",
  "receive() external payable"
];

export const getContract = (providerOrSigner) => {
  return new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, providerOrSigner);
};
