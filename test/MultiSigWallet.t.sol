pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MockTarget {
    uint256 public value;
    uint256 public lastMsgValue;

    function setValue(uint256 _value) external payable {
        value = _value;
        lastMsgValue = msg.value;
    }

    function alwaysRevert() external pure {
        revert("MockTarget: forced revert");
    }

    receive() external payable {}
}

contract MultiSigWalletTest is Test {
    MultiSigWallet public wallet;
    MockTarget public target;

    address public owner1;
    address public owner2;
    address public owner3;
    address public nonOwner;

    address[] public owners;
    uint256 public constant REQUIRED_APPROVALS = 2;
    uint256 public constant INITIAL_BALANCE = 10 ether;

    function setUp() public {
        owner1 = makeAddr("owner1");
        owner2 = makeAddr("owner2");
        owner3 = makeAddr("owner3");
        nonOwner = makeAddr("nonOwner");

        owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        wallet = new MultiSigWallet(owners, REQUIRED_APPROVALS);
        vm.deal(address(wallet), INITIAL_BALANCE);

        target = new MockTarget();
    }

    function _submitDummyTx() internal returns (uint256) {
        vm.prank(owner1);
        return wallet.submitTransaction(address(target), 0, "", "dummy tx");
    }

    function _approveByTwo(uint256 txId) internal {
        vm.prank(owner1);
        wallet.approveTransaction(txId);
        vm.prank(owner2);
        wallet.approveTransaction(txId);
    }

    // ===================== Constructor Tests =====================

    // 1. Constructor sets state correctly
    function test_constructor_setsStateCorrectly() public view {
        address[] memory o = wallet.getOwners();
        assertEq(o.length, 3);
        assertEq(o[0], owner1);
        assertTrue(wallet.isOwner(owner1));
        assertTrue(wallet.isOwner(owner2));
        assertTrue(wallet.isOwner(owner3));
        assertFalse(wallet.isOwner(nonOwner));
        assertEq(wallet.requiredApprovals(), REQUIRED_APPROVALS);
        assertEq(wallet.getTransactionCount(), 0);
    }

    // 2. Constructor reverts on empty owners array
    function test_constructor_revertsOnEmptyOwners() public {
        address[] memory empty = new address[](0);
        vm.expectRevert(MultiSigWallet.InvalidOwner.selector);
        new MultiSigWallet(empty, 1);
    }

    // 3. Constructor reverts on zero address owner
    function test_constructor_revertsOnZeroAddress() public {
        address[] memory addrs = new address[](2);
        addrs[0] = owner1;
        addrs[1] = address(0);
        vm.expectRevert(MultiSigWallet.InvalidOwner.selector);
        new MultiSigWallet(addrs, 1);
    }

    // 4. Constructor reverts on duplicate owner
    function test_constructor_revertsOnDuplicateOwner() public {
        address[] memory addrs = new address[](2);
        addrs[0] = owner1;
        addrs[1] = owner1;
        vm.expectRevert(MultiSigWallet.OwnerNotUnique.selector);
        new MultiSigWallet(addrs, 1);
    }

    // 5. Constructor reverts on invalid required approvals (0 and > owners.length)
    function test_constructor_revertsOnInvalidRequiredApprovals() public {
        vm.expectRevert(MultiSigWallet.InvalidRequiredApprovals.selector);
        new MultiSigWallet(owners, 0);

        vm.expectRevert(MultiSigWallet.InvalidRequiredApprovals.selector);
        new MultiSigWallet(owners, 4);
    }

    // ===================== Access Control Tests =====================

    // 6. submitTransaction reverts for non-owner
    function test_submitTransaction_revertsForNonOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWallet.NotOwner.selector);
        wallet.submitTransaction(address(target), 0, "", "should fail");
    }

    // 7. approveTransaction reverts for non-owner
    function test_approveTransaction_revertsForNonOwner() public {
        _submitDummyTx();
        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWallet.NotOwner.selector);
        wallet.approveTransaction(0);
    }

    // 8. executeTransaction reverts for non-owner
    function test_executeTransaction_revertsForNonOwner() public {
        _submitDummyTx();
        _approveByTwo(0);
        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWallet.NotOwner.selector);
        wallet.executeTransaction(0);
    }

    // 9. revokeApproval reverts for non-owner
    function test_revokeApproval_revertsForNonOwner() public {
        _submitDummyTx();
        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWallet.NotOwner.selector);
        wallet.revokeApproval(0);
    }

    // ===================== Submit Transaction Tests =====================

    // 10. submitTransaction stores correct fields including description
    function test_submitTransaction_storesCorrectFields() public {
        bytes memory data = abi.encodeWithSelector(MockTarget.setValue.selector, 42);
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(target), 1 ether, data, "set value to 42");

        assertEq(txId, 0);
        assertEq(wallet.getTransactionCount(), 1);
        (address to, uint256 value, bytes memory d, string memory description, bool executed, uint256 approvalCount) = wallet.getTransaction(0);
        assertEq(to, address(target));
        assertEq(value, 1 ether);
        assertEq(keccak256(d), keccak256(data));
        assertEq(keccak256(bytes(description)), keccak256(bytes("set value to 42")));
        assertFalse(executed);
        assertEq(approvalCount, 0);
    }

    // 11. submitTransaction emits SubmitTransaction event with description
    function test_submitTransaction_emitsEvent() public {
        bytes memory data = abi.encodeWithSelector(MockTarget.setValue.selector, 7);
        vm.expectEmit(true, true, true, true);
        emit MultiSigWallet.SubmitTransaction(owner1, 0, address(target), 1 ether, data, "set value to 7");
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 1 ether, data, "set value to 7");
    }

    // ===================== Approve Transaction Tests =====================

    // 12. approveTransaction updates approval count and mapping
    function test_approveTransaction_updatesState() public {
        _submitDummyTx();
        vm.prank(owner1);
        wallet.approveTransaction(0);
        (, , , , , uint256 count) = wallet.getTransaction(0);
        assertEq(count, 1);
        assertTrue(wallet.isApproved(0, owner1));
    }

    // 13. approveTransaction emits ApproveTransaction event
    function test_approveTransaction_emitsEvent() public {
        _submitDummyTx();
        vm.expectEmit(true, true, false, false);
        emit MultiSigWallet.ApproveTransaction(owner1, 0);
        vm.prank(owner1);
        wallet.approveTransaction(0);
    }

    // 14. approveTransaction reverts on non-existent tx
    function test_approveTransaction_revertsOnNonExistentTx() public {
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxDoesNotExist.selector);
        wallet.approveTransaction(0);
    }

    // 15. approveTransaction reverts on already-executed tx
    function test_approveTransaction_revertsOnAlreadyExecutedTx() public {
        _submitDummyTx();
        _approveByTwo(0);
        vm.prank(owner1);
        wallet.executeTransaction(0);

        vm.prank(owner3);
        vm.expectRevert(MultiSigWallet.TxAlreadyExecuted.selector);
        wallet.approveTransaction(0);
    }

    // 16. approveTransaction reverts on double approval
    function test_approveTransaction_revertsOnDoubleApproval() public {
        _submitDummyTx();
        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxAlreadyApproved.selector);
        wallet.approveTransaction(0);
    }

    // ===================== Execute Transaction Tests =====================

    // 17. executeTransaction transfers ETH correctly
    function test_executeTransaction_transfersEth() public {
        address payable recipient = payable(makeAddr("recipient"));
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "", "send 1 eth");
        _approveByTwo(txId);

        vm.prank(owner1);
        wallet.executeTransaction(txId);

        assertEq(recipient.balance, 1 ether);
        assertEq(address(wallet).balance, INITIAL_BALANCE - 1 ether);
    }

    // 18. executeTransaction executes calldata on target
    function test_executeTransaction_executesCalldata() public {
        bytes memory data = abi.encodeWithSelector(MockTarget.setValue.selector, 42);
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(target), 0, data, "call setValue(42)");
        _approveByTwo(txId);
        vm.prank(owner1);
        wallet.executeTransaction(txId);
        assertEq(target.value(), 42);
    }

    // 19. executeTransaction emits ExecuteTransaction event
    function test_executeTransaction_emitsEvent() public {
        _submitDummyTx();
        _approveByTwo(0);
        vm.expectEmit(true, true, false, false);
        emit MultiSigWallet.ExecuteTransaction(owner1, 0);
        vm.prank(owner1);
        wallet.executeTransaction(0);
    }

    // 20. executeTransaction reverts on non-existent tx
    function test_executeTransaction_revertsOnNonExistentTx() public {
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxDoesNotExist.selector);
        wallet.executeTransaction(999);
    }

    // 21. executeTransaction reverts on already-executed tx
    function test_executeTransaction_revertsOnAlreadyExecuted() public {
        _submitDummyTx();
        _approveByTwo(0);
        vm.prank(owner1);
        wallet.executeTransaction(0);
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxAlreadyExecuted.selector);
        wallet.executeTransaction(0);
    }

    // 22. executeTransaction reverts on insufficient approvals
    function test_executeTransaction_revertsOnInsufficientApprovals() public {
        _submitDummyTx();
        vm.prank(owner1);
        wallet.approveTransaction(0);
        // Only 1 of 2 required
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.InsufficientApprovals.selector);
        wallet.executeTransaction(0);
    }

    // 23. executeTransaction reverts when target call fails
    function test_executeTransaction_revertsOnFailedCall() public {
        bytes memory data = abi.encodeWithSelector(MockTarget.alwaysRevert.selector);
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(target), 0, data, "will revert");
        _approveByTwo(txId);
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxFailed.selector);
        wallet.executeTransaction(txId);
    }

    // ===================== Revoke Approval Tests =====================

    // 24. revokeApproval decrements count and updates mapping
    function test_revokeApproval_decrementsCountAndUpdatesMapping() public {
        _submitDummyTx();
        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.prank(owner1);
        wallet.revokeApproval(0);
        (, , , , , uint256 count) = wallet.getTransaction(0);
        assertEq(count, 0);
        assertFalse(wallet.isApproved(0, owner1));
    }

    // 25. revokeApproval emits RevokeApproval event
    function test_revokeApproval_emitsEvent() public {
        _submitDummyTx();
        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.expectEmit(true, true, false, false);
        emit MultiSigWallet.RevokeApproval(owner1, 0);
        vm.prank(owner1);
        wallet.revokeApproval(0);
    }

    // 26. revokeApproval reverts on executed tx
    function test_revokeApproval_revertsOnExecutedTx() public {
        _submitDummyTx();
        _approveByTwo(0);
        vm.prank(owner1);
        wallet.executeTransaction(0);
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxAlreadyExecuted.selector);
        wallet.revokeApproval(0);
    }

    // 27. revokeApproval reverts when caller has not approved
    function test_revokeApproval_revertsWhenNotApproved() public {
        _submitDummyTx();
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxNotApproved.selector);
        wallet.revokeApproval(0);
    }

    // 28. revokeApproval blocks execution until re-approved
    function test_revokeApproval_blocksExecutionUntilReApproved() public {
        _submitDummyTx();
        _approveByTwo(0);
        vm.prank(owner1);
        wallet.revokeApproval(0);
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.InsufficientApprovals.selector);
        wallet.executeTransaction(0);

        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.prank(owner1);
        wallet.executeTransaction(0);
        (, , , , bool executed, ) = wallet.getTransaction(0);
        assertTrue(executed);
    }

    // ===================== Receive / Deposit Tests =====================

    // 29. receive() accepts ETH and emits Deposit event
    function test_receive_acceptsEthAndEmitsDeposit() public {
        vm.deal(nonOwner, 5 ether);
        vm.expectEmit(true, false, false, true);
        emit MultiSigWallet.Deposit(nonOwner, 5 ether, INITIAL_BALANCE + 5 ether);
        vm.prank(nonOwner);
        (bool ok, ) = address(wallet).call{value: 5 ether}("");
        assertTrue(ok);
        assertEq(address(wallet).balance, INITIAL_BALANCE + 5 ether);
    }

    // ===================== End-to-End Tests =====================

    // 30. Full happy path end-to-end test
    function test_fullHappyPath_endToEnd() public {
        bytes memory data = abi.encodeWithSelector(MockTarget.setValue.selector, 777);
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(target), 1 ether, data, "e2e: set 777 with 1 eth");

        vm.prank(owner1);
        wallet.approveTransaction(txId);

        vm.prank(owner2);
        wallet.approveTransaction(txId);

        vm.prank(owner3);
        wallet.executeTransaction(txId);

        assertEq(target.value(), 777);
        assertEq(target.lastMsgValue(), 1 ether);
        (, , , , bool executed, uint256 approvalCount) = wallet.getTransaction(txId);
        assertTrue(executed);
        assertEq(approvalCount, 2);
    }
}
