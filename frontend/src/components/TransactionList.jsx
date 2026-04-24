import React, { useState } from 'react';
import { ethers } from 'ethers';

const TransactionList = ({ transactions, contract, account, fetchTransactions, isOwner }) => {
  const [loadingTxId, setLoadingTxId] = useState(null);

  const handleAction = async (action, txId) => {
    try {
      setLoadingTxId(txId);
      let tx;
      if (action === 'approve') {
        tx = await contract.approveTransaction(txId);
      } else if (action === 'revoke') {
        tx = await contract.revokeApproval(txId);
      } else if (action === 'execute') {
        tx = await contract.executeTransaction(txId);
      }
      
      await tx.wait();
      await fetchTransactions();
    } catch (err) {
      console.error(err);
      alert(err.reason || err.message || `Failed to ${action} transaction`);
    } finally {
      setLoadingTxId(null);
    }
  };

  if (transactions.length === 0) {
    return (
      <div className="glass-card" style={{ textAlign: 'center', padding: '5rem 2rem' }}>
        <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth="1" style={{ marginBottom: '1.5rem' }}>
          <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
          <line x1="3" y1="9" x2="21" y2="9"></line>
          <line x1="9" y1="21" x2="9" y2="9"></line>
        </svg>
        <h3 style={{ color: 'var(--text-muted)' }}>No Active Proposals</h3>
      </div>
    );
  }

  return (
    <div>
      <h2 style={{ marginBottom: '2rem', fontSize: '1.8rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="var(--color-primary)" strokeWidth="2">
          <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>
        </svg>
        Ledger Queue
      </h2>

      {transactions.map((tx) => (
        <div key={tx.id} className={`tx-item ${tx.executed ? 'executed' : ''}`}>
          <div className="tx-head">
            <span className="tx-number">
              <span style={{ color: 'var(--text-muted)' }}>#</span>{tx.id}
            </span>
            <span className={`tag ${tx.executed ? 'tag-done' : 'tag-pending'}`}>
              {tx.executed ? 'Executed' : 'Pending'}
            </span>
          </div>
          
          {tx.description && (
            <div style={{ marginBottom: '1.5rem', padding: '1rem', background: 'rgba(0, 229, 255, 0.05)', borderRadius: 'var(--radius-sm)', borderLeft: '3px solid var(--color-secondary)' }}>
              <p style={{ margin: 0, color: '#fff', fontSize: '1.05rem', lineHeight: '1.5' }}>
                <strong style={{ color: 'var(--color-secondary)', fontSize: '0.85rem', textTransform: 'uppercase', letterSpacing: '1px', display: 'block', marginBottom: '0.25rem' }}>Proposal Description</strong>
                {tx.description}
              </p>
            </div>
          )}
          
          <div className="data-grid">
            <div className="data-col">
              <span className="data-lbl">Target Address</span>
              <span className="data-val" title={tx.to}>{tx.to.substring(0, 8)}...{tx.to.substring(36)}</span>
            </div>
            <div className="data-col">
              <span className="data-lbl">Transfer Value</span>
              <span className="data-val accent">{ethers.formatEther(tx.value)} ETH</span>
            </div>
            {tx.data !== '0x' && (
              <div className="data-col" style={{ gridColumn: '1 / -1' }}>
                <span className="data-lbl">Execution Data</span>
                <span className="data-val" style={{ color: 'var(--text-muted)' }}>{tx.data.length > 40 ? `${tx.data.substring(0, 40)}...` : tx.data}</span>
              </div>
            )}
            
            <div className="data-col" style={{ gridColumn: '1 / -1', marginTop: '0.5rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: 'rgba(0,0,0,0.3)', padding: '1rem 1.5rem', borderRadius: 'var(--radius-sm)', border: '1px solid rgba(255,255,255,0.05)' }}>
                <span className="data-lbl" style={{ margin: 0 }}>Consensus Status</span>
                <span style={{ fontSize: '1.6rem', fontWeight: '800', fontFamily: 'var(--font-display)', color: tx.executed ? 'var(--color-success)' : 'var(--color-secondary)' }}>
                  {tx.approvalCount.toString()}
                </span>
              </div>
            </div>
          </div>
          
          {isOwner && !tx.executed && (
            <div style={{ display: 'flex', gap: '1rem', marginTop: '2rem' }}>
              {!tx.hasApproved ? (
                <button 
                  className="btn btn-success" 
                  onClick={() => handleAction('approve', tx.id)}
                  disabled={loadingTxId === tx.id}
                  style={{ flex: 1, padding: '0.8rem' }}
                >
                  {loadingTxId === tx.id ? <span className="loader-ring"></span> : 'Approve'}
                </button>
              ) : (
                <button 
                  className="btn btn-danger" 
                  onClick={() => handleAction('revoke', tx.id)}
                  disabled={loadingTxId === tx.id}
                  style={{ flex: 1, padding: '0.8rem' }}
                >
                  {loadingTxId === tx.id ? <span className="loader-ring"></span> : 'Revoke'}
                </button>
              )}
              
              <button 
                className="btn btn-glow" 
                onClick={() => handleAction('execute', tx.id)}
                disabled={loadingTxId === tx.id}
                style={{ flex: 1, padding: '0.8rem' }}
              >
                <span>{loadingTxId === tx.id ? <span className="loader-ring"></span> : 'Execute'}</span>
              </button>
            </div>
          )}
        </div>
      ))}
    </div>
  );
};

export default TransactionList;
