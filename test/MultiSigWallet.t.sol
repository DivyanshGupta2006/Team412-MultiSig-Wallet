// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

/**
 * @title MultiSigWalletTest
 * @notice Comprehensive test suite for the MultiSigWallet contract.
 *         Covers all rubric requirements: access control, happy path,
 *         edge cases, revert tests, and ETH handling.
 */
contract MultiSigWalletTest is Test {
    MultiSigWallet public wallet;

    address public owner1;
    address public owner2;
    address public owner3;
    address public nonOwner;

    // Target contract for testing execution
    TargetContract public target;

    /// @notice Set up the test environment with a 2-of-3 multi-sig wallet.
    function setUp() public {
        owner1 = makeAddr("owner1");
        owner2 = makeAddr("owner2");
        owner3 = makeAddr("owner3");
        nonOwner = makeAddr("nonOwner");

        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        wallet = new MultiSigWallet(owners, 2); // 2-of-3
        target = new TargetContract();

        // Fund the wallet with 10 ETH
        vm.deal(address(wallet), 10 ether);
    }

    // ═══════════════════════════════════════════════
    //  Constructor Tests
    // ═══════════════════════════════════════════════

    function test_constructor_setsOwnersCorrectly() public view {
        address[] memory owners = wallet.getOwners();
        assertEq(owners.length, 3);
        assertEq(owners[0], owner1);
        assertEq(owners[1], owner2);
        assertEq(owners[2], owner3);
    }

    function test_constructor_setsRequiredApprovals() public view {
        assertEq(wallet.requiredApprovals(), 2);
    }

    function test_constructor_isOwnerMapping() public view {
        assertTrue(wallet.isOwner(owner1));
        assertTrue(wallet.isOwner(owner2));
        assertTrue(wallet.isOwner(owner3));
        assertFalse(wallet.isOwner(nonOwner));
    }

    function test_constructor_revertsOnEmptyOwners() public {
        address[] memory owners = new address[](0);
        vm.expectRevert(MultiSigWallet.InvalidOwner.selector);
        new MultiSigWallet(owners, 1);
    }

    function test_constructor_revertsOnZeroAddressOwner() public {
        address[] memory owners = new address[](2);
        owners[0] = owner1;
        owners[1] = address(0);
        vm.expectRevert(MultiSigWallet.InvalidOwner.selector);
        new MultiSigWallet(owners, 1);
    }

    function test_constructor_revertsOnDuplicateOwners() public {
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner1; // duplicate
        vm.expectRevert(MultiSigWallet.OwnerNotUnique.selector);
        new MultiSigWallet(owners, 2);
    }

    function test_constructor_revertsOnZeroRequiredApprovals() public {
        address[] memory owners = new address[](2);
        owners[0] = owner1;
        owners[1] = owner2;
        vm.expectRevert(MultiSigWallet.InvalidRequiredApprovals.selector);
        new MultiSigWallet(owners, 0);
    }

    function test_constructor_revertsOnTooManyRequiredApprovals() public {
        address[] memory owners = new address[](2);
        owners[0] = owner1;
        owners[1] = owner2;
        vm.expectRevert(MultiSigWallet.InvalidRequiredApprovals.selector);
        new MultiSigWallet(owners, 3); // 3 > 2 owners
    }

    // ═══════════════════════════════════════════════
    //  Receive / Deposit Tests
    // ═══════════════════════════════════════════════

    function test_receive_acceptsEther() public {
        uint256 balBefore = address(wallet).balance;
        vm.deal(nonOwner, 5 ether);
        vm.prank(nonOwner);
        (bool ok, ) = address(wallet).call{value: 1 ether}("");
        assertTrue(ok);
        assertEq(address(wallet).balance, balBefore + 1 ether);
    }

    function test_receive_emitsDeposit() public {
        vm.deal(nonOwner, 5 ether);
        vm.prank(nonOwner);
        vm.expectEmit(true, false, false, true);
        emit MultiSigWallet.Deposit(nonOwner, 1 ether, address(wallet).balance + 1 ether);
        (bool ok, ) = address(wallet).call{value: 1 ether}("");
        assertTrue(ok);
    }

    // ═══════════════════════════════════════════════
    //  Access Control Tests
    // ═══════════════════════════════════════════════

    function test_nonOwner_cannotSubmit() public {
        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWallet.NotOwner.selector);
        wallet.submitTransaction(address(target), 0, "");
    }

    function test_nonOwner_cannotApprove() public {
        // First submit as owner
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, "");

        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWallet.NotOwner.selector);
        wallet.approveTransaction(0);
    }

    function test_nonOwner_cannotExecute() public {
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, "");
        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.prank(owner2);
        wallet.approveTransaction(0);

        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWallet.NotOwner.selector);
        wallet.executeTransaction(0);
    }

    function test_nonOwner_cannotRevokeApproval() public {
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, "");
        vm.prank(owner1);
        wallet.approveTransaction(0);

        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWallet.NotOwner.selector);
        wallet.revokeApproval(0);
    }

    // ═══════════════════════════════════════════════
    //  Submit Transaction Tests
    // ═══════════════════════════════════════════════

    function test_submitTransaction_storesCorrectly() public {
        bytes memory data = abi.encodeWithSignature("setValue(uint256)", 42);

        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(target), 1 ether, data);

        assertEq(txId, 0);
        assertEq(wallet.getTransactionCount(), 1);

        (address to, uint256 value, bytes memory txData, bool executed, uint256 approvalCount) =
            wallet.getTransaction(0);

        assertEq(to, address(target));
        assertEq(value, 1 ether);
        assertEq(txData, data);
        assertFalse(executed);
        assertEq(approvalCount, 0);
    }

    function test_submitTransaction_returnsTxId() public {
        vm.prank(owner1);
        uint256 txId0 = wallet.submitTransaction(address(target), 0, "");
        assertEq(txId0, 0);

        vm.prank(owner2);
        uint256 txId1 = wallet.submitTransaction(address(target), 0, "");
        assertEq(txId1, 1);
    }

    function test_submitTransaction_emitsEvent() public {
        bytes memory data = abi.encodeWithSignature("setValue(uint256)", 42);

        vm.prank(owner1);
        vm.expectEmit(true, true, true, true);
        emit MultiSigWallet.SubmitTransaction(owner1, 0, address(target), 1 ether, data);
        wallet.submitTransaction(address(target), 1 ether, data);
    }

    // ═══════════════════════════════════════════════
    //  Approve Transaction Tests
    // ═══════════════════════════════════════════════

    function test_approveTransaction_incrementsCount() public {
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, "");

        vm.prank(owner1);
        wallet.approveTransaction(0);

        (, , , , uint256 approvalCount) = wallet.getTransaction(0);
        assertEq(approvalCount, 1);
        assertTrue(wallet.isApproved(0, owner1));
    }

    function test_approveTransaction_emitsEvent() public {
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, "");

        vm.prank(owner1);
        vm.expectEmit(true, true, false, true);
        emit MultiSigWallet.ApproveTransaction(owner1, 0);
        wallet.approveTransaction(0);
    }

    function test_approveTransaction_preventsDoubleApprove() public {
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, "");

        vm.prank(owner1);
        wallet.approveTransaction(0);

        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxAlreadyApproved.selector);
        wallet.approveTransaction(0);
    }

    function test_approveTransaction_revertsOnNonExistentTx() public {
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxDoesNotExist.selector);
        wallet.approveTransaction(999);
    }

    function test_approveTransaction_revertsOnExecutedTx() public {
        // Submit, approve (2 of 3), execute
        _submitApproveAndExecute();

        vm.prank(owner3);
        vm.expectRevert(MultiSigWallet.TxAlreadyExecuted.selector);
        wallet.approveTransaction(0);
    }

    // ═══════════════════════════════════════════════
    //  Execute Transaction Tests
    // ═══════════════════════════════════════════════

    function test_executeTransaction_happyPath() public {
        // Submit a tx that calls target.setValue(42)
        bytes memory data = abi.encodeWithSignature("setValue(uint256)", 42);
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, data);

        // owner1 approves
        vm.prank(owner1);
        wallet.approveTransaction(0);

        // owner2 approves (now 2/2 required)
        vm.prank(owner2);
        wallet.approveTransaction(0);

        // owner1 executes
        vm.prank(owner1);
        wallet.executeTransaction(0);

        // Verify the target state changed
        assertEq(target.value(), 42);

        // Verify tx marked as executed
        (, , , bool executed, ) = wallet.getTransaction(0);
        assertTrue(executed);
    }

    function test_executeTransaction_sendsEther() public {
        address payable recipient = payable(makeAddr("recipient"));

        vm.prank(owner1);
        wallet.submitTransaction(recipient, 2 ether, "");

        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.prank(owner2);
        wallet.approveTransaction(0);

        uint256 recipientBalBefore = recipient.balance;

        vm.prank(owner1);
        wallet.executeTransaction(0);

        assertEq(recipient.balance, recipientBalBefore + 2 ether);
    }

    function test_executeTransaction_emitsEvent() public {
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, "");

        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.prank(owner2);
        wallet.approveTransaction(0);

        vm.prank(owner1);
        vm.expectEmit(true, true, false, true);
        emit MultiSigWallet.ExecuteTransaction(owner1, 0);
        wallet.executeTransaction(0);
    }

    function test_executeTransaction_revertsWithFewerThanMApprovals() public {
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, "");

        // Only 1 approval (need 2)
        vm.prank(owner1);
        wallet.approveTransaction(0);

        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.InsufficientApprovals.selector);
        wallet.executeTransaction(0);
    }

    function test_executeTransaction_revertsOnAlreadyExecuted() public {
        _submitApproveAndExecute();

        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxAlreadyExecuted.selector);
        wallet.executeTransaction(0);
    }

    function test_executeTransaction_revertsOnNonExistentTx() public {
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxDoesNotExist.selector);
        wallet.executeTransaction(999);
    }

    function test_executeTransaction_revertsOnFailedCall() public {
        // Submit a tx to a contract that will revert
        bytes memory data = abi.encodeWithSignature("alwaysReverts()");
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, data);

        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.prank(owner2);
        wallet.approveTransaction(0);

        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxFailed.selector);
        wallet.executeTransaction(0);
    }

    // ═══════════════════════════════════════════════
    //  Revoke Approval Tests
    // ═══════════════════════════════════════════════

    function test_revokeApproval_decrementsCount() public {
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, "");

        vm.prank(owner1);
        wallet.approveTransaction(0);

        (, , , , uint256 countBefore) = wallet.getTransaction(0);
        assertEq(countBefore, 1);

        vm.prank(owner1);
        wallet.revokeApproval(0);

        (, , , , uint256 countAfter) = wallet.getTransaction(0);
        assertEq(countAfter, 0);
        assertFalse(wallet.isApproved(0, owner1));
    }

    function test_revokeApproval_blocksExecuteUntilReApproved() public {
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, "");

        // 2 approvals
        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.prank(owner2);
        wallet.approveTransaction(0);

        // owner1 revokes — now only 1 approval
        vm.prank(owner1);
        wallet.revokeApproval(0);

        // Execute should fail
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.InsufficientApprovals.selector);
        wallet.executeTransaction(0);

        // owner1 re-approves — back to 2
        vm.prank(owner1);
        wallet.approveTransaction(0);

        // Now execution succeeds
        vm.prank(owner1);
        wallet.executeTransaction(0);

        (, , , bool executed, ) = wallet.getTransaction(0);
        assertTrue(executed);
    }

    function test_revokeApproval_emitsEvent() public {
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, "");

        vm.prank(owner1);
        wallet.approveTransaction(0);

        vm.prank(owner1);
        vm.expectEmit(true, true, false, true);
        emit MultiSigWallet.RevokeApproval(owner1, 0);
        wallet.revokeApproval(0);
    }

    function test_revokeApproval_revertsIfNotApproved() public {
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, "");

        vm.prank(owner1); // owner1 never approved
        vm.expectRevert(MultiSigWallet.TxNotApproved.selector);
        wallet.revokeApproval(0);
    }

    function test_revokeApproval_revertsOnExecutedTx() public {
        _submitApproveAndExecute();

        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxAlreadyExecuted.selector);
        wallet.revokeApproval(0);
    }

    function test_revokeApproval_revertsOnNonExistentTx() public {
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxDoesNotExist.selector);
        wallet.revokeApproval(999);
    }

    // ═══════════════════════════════════════════════
    //  View Function Tests
    // ═══════════════════════════════════════════════

    function test_getOwners_returnsAll() public view {
        address[] memory result = wallet.getOwners();
        assertEq(result.length, 3);
    }

    function test_getTransactionCount_incrementsOnSubmit() public {
        assertEq(wallet.getTransactionCount(), 0);

        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, "");
        assertEq(wallet.getTransactionCount(), 1);

        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, "");
        assertEq(wallet.getTransactionCount(), 2);
    }

    // ═══════════════════════════════════════════════
    //  Full Integration / Happy Path
    // ═══════════════════════════════════════════════

    function test_fullHappyPath_submitApproveExecuteVerify() public {
        // 1. Submit: owner1 proposes sending 1 ETH and calling setValue(100)
        bytes memory data = abi.encodeWithSignature("setValue(uint256)", 100);
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(target), 1 ether, data);
        assertEq(txId, 0);

        // 2. Approve: owner1 and owner2 approve (M = 2)
        vm.prank(owner1);
        wallet.approveTransaction(txId);
        vm.prank(owner2);
        wallet.approveTransaction(txId);

        // 3. Execute: owner3 executes
        uint256 targetBalBefore = address(target).balance;
        vm.prank(owner3);
        wallet.executeTransaction(txId);

        // 4. Verify state changes
        assertEq(target.value(), 100); // target state changed
        assertEq(address(target).balance, targetBalBefore + 1 ether); // ETH sent

        (, , , bool executed, uint256 approvalCount) = wallet.getTransaction(txId);
        assertTrue(executed);
        assertEq(approvalCount, 2);
    }

    function test_ethReceiptAndSendout() public {
        // Receive ETH
        uint256 balBefore = address(wallet).balance;
        vm.deal(nonOwner, 3 ether);
        vm.prank(nonOwner);
        (bool ok, ) = address(wallet).call{value: 3 ether}("");
        assertTrue(ok);
        assertEq(address(wallet).balance, balBefore + 3 ether);

        // Send ETH out via multi-sig
        address payable dest = payable(makeAddr("dest"));
        vm.prank(owner1);
        wallet.submitTransaction(dest, 2 ether, "");
        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.prank(owner2);
        wallet.approveTransaction(0);
        vm.prank(owner1);
        wallet.executeTransaction(0);

        assertEq(dest.balance, 2 ether);
    }

    // ═══════════════════════════════════════════════
    //  Internal Helpers
    // ═══════════════════════════════════════════════

    /// @dev Helper: submit tx 0, approve with owner1 & owner2, execute as owner1.
    function _submitApproveAndExecute() internal {
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 0, "");

        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.prank(owner2);
        wallet.approveTransaction(0);

        vm.prank(owner1);
        wallet.executeTransaction(0);
    }
}

// ═══════════════════════════════════════════════════
//  Helper: Target contract for testing execution
// ═══════════════════════════════════════════════════

/// @notice A simple target contract to verify that the multi-sig
///         can call external contracts and send ETH.
contract TargetContract {
    uint256 public value;

    /// @notice Sets a value — used to verify multi-sig execution.
    function setValue(uint256 _value) external payable {
        value = _value;
    }

    /// @notice Always reverts — used to test failed execution handling.
    function alwaysReverts() external pure {
        revert("TargetContract: forced revert");
    }

    /// @notice Allows the contract to receive ETH.
    receive() external payable {}
}
