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
        return wallet.submitTransaction(address(target), 0, "");
    }

    function _approveByTwo(uint256 txId) internal {
        vm.prank(owner1);
        wallet.approveTransaction(txId);
        vm.prank(owner2);
        wallet.approveTransaction(txId);
    }

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

    function test_constructor_revertsOnEmptyOwners() public {
        address[] memory empty = new address[](0);
        vm.expectRevert(MultiSigWallet.InvalidOwner.selector);
        new MultiSigWallet(empty, 1);
    }

    function test_constructor_revertsOnZeroAddress() public {
        address[] memory addrs = new address[](2);
        addrs[0] = owner1;
        addrs[1] = address(0);
        vm.expectRevert(MultiSigWallet.InvalidOwner.selector);
        new MultiSigWallet(addrs, 1);
    }

    function test_constructor_revertsOnDuplicateOwner() public {
        address[] memory addrs = new address[](2);
        addrs[0] = owner1;
        addrs[1] = owner1;
        vm.expectRevert(MultiSigWallet.OwnerNotUnique.selector);
        new MultiSigWallet(addrs, 1);
    }

    function test_constructor_revertsOnInvalidRequiredApprovals() public {
        vm.expectRevert(MultiSigWallet.InvalidRequiredApprovals.selector);
        new MultiSigWallet(owners, 0);

        vm.expectRevert(MultiSigWallet.InvalidRequiredApprovals.selector);
        new MultiSigWallet(owners, 4);
    }

    function test_submitTransaction_revertsForNonOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWallet.NotOwner.selector);
        wallet.submitTransaction(address(target), 0, "");
    }

    function test_approveTransaction_revertsForNonOwner() public {
        _submitDummyTx();
        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWallet.NotOwner.selector);
        wallet.approveTransaction(0);
    }

    function test_executeTransaction_revertsForNonOwner() public {
        _submitDummyTx();
        _approveByTwo(0);
        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWallet.NotOwner.selector);
        wallet.executeTransaction(0);
    }

    function test_revokeApproval_revertsForNonOwner() public {
        _submitDummyTx();
        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWallet.NotOwner.selector);
        wallet.revokeApproval(0);
    }

    function test_submitTransaction_storesCorrectFields() public {
        bytes memory data = abi.encodeWithSelector(MockTarget.setValue.selector, 42);
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(target), 1 ether, data);

        assertEq(txId, 0);
        assertEq(wallet.getTransactionCount(), 1);
        (address to, uint256 value, bytes memory d, bool executed, uint256 approvalCount) = wallet.getTransaction(0);
        assertEq(to, address(target));
        assertEq(value, 1 ether);
        assertEq(keccak256(d), keccak256(data));
        assertFalse(executed);
        assertEq(approvalCount, 0);
    }

    function test_submitTransaction_emitsEvent() public {
        bytes memory data = abi.encodeWithSelector(MockTarget.setValue.selector, 7);
        vm.expectEmit(true, true, true, true);
        emit MultiSigWallet.SubmitTransaction(owner1, 0, address(target), 1 ether, data);
        vm.prank(owner1);
        wallet.submitTransaction(address(target), 1 ether, data);
    }

    function test_approveTransaction_updatesState() public {
        _submitDummyTx();
        vm.prank(owner1);
        wallet.approveTransaction(0);
        (, , , , uint256 count) = wallet.getTransaction(0);
        assertEq(count, 1);
        assertTrue(wallet.isApproved(0, owner1));
    }

    function test_approveTransaction_emitsEvent() public {
        _submitDummyTx();
        vm.expectEmit(true, true, false, false);
        emit MultiSigWallet.ApproveTransaction(owner1, 0);
        vm.prank(owner1);
        wallet.approveTransaction(0);
    }

    function test_approveTransaction_revertsOnNonExistentTx() public {
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxDoesNotExist.selector);
        wallet.approveTransaction(0);
    }

    function test_approveTransaction_revertsOnAlreadyExecutedTx() public {
        _submitDummyTx();
        _approveByTwo(0);
        vm.prank(owner1);
        wallet.executeTransaction(0);

        vm.prank(owner3);
        vm.expectRevert(MultiSigWallet.TxAlreadyExecuted.selector);
        wallet.approveTransaction(0);
    }

    function test_approveTransaction_revertsOnDoubleApproval() public {
        _submitDummyTx();
        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxAlreadyApproved.selector);
        wallet.approveTransaction(0);
    }

    function test_executeTransaction_transfersEth() public {
        address payable recipient = payable(makeAddr("recipient"));
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(recipient, 1 ether, "");
        _approveByTwo(txId);

        vm.prank(owner1);
        wallet.executeTransaction(txId);

        assertEq(recipient.balance, 1 ether);
        assertEq(address(wallet).balance, INITIAL_BALANCE - 1 ether);
    }

    function test_executeTransaction_executesCalldata() public {
        bytes memory data = abi.encodeWithSelector(MockTarget.setValue.selector, 42);
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(target), 0, data);
        _approveByTwo(txId);
        vm.prank(owner1);
        wallet.executeTransaction(txId);
        assertEq(target.value(), 42);
    }

    function test_executeTransaction_emitsEvent() public {
        _submitDummyTx();
        _approveByTwo(0);
        vm.expectEmit(true, true, false, false);
        emit MultiSigWallet.ExecuteTransaction(owner1, 0);
        vm.prank(owner1);
        wallet.executeTransaction(0);
    }

    function test_executeTransaction_revertsOnNonExistentTx() public {
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxDoesNotExist.selector);
        wallet.executeTransaction(999);
    }

    function test_executeTransaction_revertsOnAlreadyExecuted() public {
        _submitDummyTx();
        _approveByTwo(0);
        vm.prank(owner1);
        wallet.executeTransaction(0);
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxAlreadyExecuted.selector);
        wallet.executeTransaction(0);
    }

    function test_executeTransaction_revertsOnInsufficientApprovals() public {
        _submitDummyTx();
        vm.prank(owner1);
        wallet.approveTransaction(0);
        // Only 1 of 2 required
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.InsufficientApprovals.selector);
        wallet.executeTransaction(0);
    }

    function test_executeTransaction_revertsOnFailedCall() public {
        bytes memory data = abi.encodeWithSelector(MockTarget.alwaysRevert.selector);
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(target), 0, data);
        _approveByTwo(txId);
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxFailed.selector);
        wallet.executeTransaction(txId);
    }

    function test_revokeApproval_decrementsCountAndUpdatesMapping() public {
        _submitDummyTx();
        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.prank(owner1);
        wallet.revokeApproval(0);
        (, , , , uint256 count) = wallet.getTransaction(0);
        assertEq(count, 0);
        assertFalse(wallet.isApproved(0, owner1));
    }

    function test_revokeApproval_emitsEvent() public {
        _submitDummyTx();
        vm.prank(owner1);
        wallet.approveTransaction(0);
        vm.expectEmit(true, true, false, false);
        emit MultiSigWallet.RevokeApproval(owner1, 0);
        vm.prank(owner1);
        wallet.revokeApproval(0);
    }

    function test_revokeApproval_revertsOnExecutedTx() public {
        _submitDummyTx();
        _approveByTwo(0);
        vm.prank(owner1);
        wallet.executeTransaction(0);
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxAlreadyExecuted.selector);
        wallet.revokeApproval(0);
    }

    function test_revokeApproval_revertsWhenNotApproved() public {
        _submitDummyTx();
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TxNotApproved.selector);
        wallet.revokeApproval(0);
    }

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
        (, , , bool executed, ) = wallet.getTransaction(0);
        assertTrue(executed);
    }

    function test_receive_acceptsEthAndEmitsDeposit() public {
        vm.deal(nonOwner, 5 ether);
        vm.expectEmit(true, false, false, true);
        emit MultiSigWallet.Deposit(nonOwner, 5 ether, INITIAL_BALANCE + 5 ether);
        vm.prank(nonOwner);
        (bool ok, ) = address(wallet).call{value: 5 ether}("");
        assertTrue(ok);
        assertEq(address(wallet).balance, INITIAL_BALANCE + 5 ether);
    }

    function test_fullHappyPath_endToEnd() public {
        bytes memory data = abi.encodeWithSelector(MockTarget.setValue.selector, 777);
        vm.prank(owner1);
        uint256 txId = wallet.submitTransaction(address(target), 1 ether, data);

        vm.prank(owner1);
        wallet.approveTransaction(txId);

        vm.prank(owner2);
        wallet.approveTransaction(txId);

        vm.prank(owner3);
        wallet.executeTransaction(txId);

        assertEq(target.value(), 777);
        assertEq(target.lastMsgValue(), 1 ether);
        (, , , bool executed, uint256 approvalCount) = wallet.getTransaction(txId);
        assertTrue(executed);
        assertEq(approvalCount, 2);
    }
}
