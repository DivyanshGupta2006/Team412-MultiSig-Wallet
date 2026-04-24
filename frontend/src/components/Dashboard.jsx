import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import SubmitTransaction from './SubmitTransaction';
import TransactionList from './TransactionList';
import ActivityChart from './ActivityChart';
import OwnersList from './OwnersList';

const Dashboard = ({ account, contract, provider, disconnectWallet }) => {
  const [walletBalance, setWalletBalance] = useState('0');
  const [owners, setOwners] = useState([]);
  const [requiredApprovals, setRequiredApprovals] = useState(0);
  const [isOwner, setIsOwner] = useState(false);
  const [transactions, setTransactions] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchWalletDetails = async () => {
    try {
      if (!contract) return;
      
      const [balance, ownerList, required, txCount] = await Promise.all([
        provider.getBalance(await contract.getAddress()),
        contract.getOwners(),
        contract.requiredApprovals(),
        contract.getTransactionCount()
      ]);

      setWalletBalance(ethers.formatEther(balance));
      setOwners(ownerList);
      setRequiredApprovals(Number(required));
      
      const isUserOwner = ownerList.map(o => o.toLowerCase()).includes(account.toLowerCase());
      setIsOwner(isUserOwner);

      const txs = [];
      for (let i = 0; i < Number(txCount); i++) {
        const tx = await contract.getTransaction(i);
        let hasApproved = false;
        if (isUserOwner) {
          hasApproved = await contract.isApproved(i, account);
        }
        
        txs.push({
          id: i,
          to: tx.to,
          value: tx.value,
          data: tx.data,
          description: tx.description,
          executed: tx.executed,
          approvalCount: tx.approvalCount,
          hasApproved
        });
      }
      
      setTransactions(txs.reverse());
    } catch (err) {
      console.error("Error fetching wallet details:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchWalletDetails();
  }, [contract, account]);

  if (loading) {
    return (
      <div className="container" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '80vh', gap: '2rem' }}>
        <div className="loader-ring loader-huge"></div>
        <p className="text-gradient-primary" style={{ fontFamily: 'var(--font-display)', fontWeight: '700', fontSize: '1.5rem', letterSpacing: '0.2em' }}>SYNCING CORE...</p>
      </div>
    );
  }

  return (
    <>
      <div className="mesh-bg" style={{ opacity: 0.5 }}>
        <div className="mesh-blob mesh-blob-1" style={{ animationDuration: '40s' }}></div>
        <div className="mesh-blob mesh-blob-2" style={{ animationDuration: '45s' }}></div>
      </div>

      <div className="container">
        <header className="header-ultra fade-up">
          <div className="brand">
            <div className="brand-icon">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
                <polygon points="12 2 2 7 12 12 22 7 12 2"></polygon>
                <polyline points="2 17 12 22 22 17"></polyline>
                <polyline points="2 12 12 17 22 12"></polyline>
              </svg>
            </div>
            Multi-Sig Wallet
          </div>
          
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <div className="wallet-chip">
              <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: 'var(--color-success)', boxShadow: '0 0 10px var(--color-success)' }}></div>
              {account.substring(0, 6)}...{account.substring(38)}
              {isOwner && <span className="owner-badge">Signer</span>}
            </div>
            
            <button 
              onClick={disconnectWallet} 
              title="Disconnect"
              className="btn btn-outline"
              style={{ padding: '0.6rem', borderRadius: '50%', display: 'flex' }}
            >
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--color-tertiary)" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                <polyline points="16 17 21 12 16 7"></polyline>
                <line x1="21" y1="12" x2="9" y2="12"></line>
              </svg>
            </button>
          </div>
        </header>

        {/* Stats Row */}
        <div className="stats-grid fade-up d-1">
          <div className="stat-box">
            <div className="stat-title">Vault TVL</div>
            <div className="stat-val text-gradient-primary">
              {Number(walletBalance).toFixed(4)} <span>ETH</span>
            </div>
          </div>
          
          <div className="stat-box">
            <div className="stat-title">Network Consensus</div>
            <div className="stat-val">
              {requiredApprovals} <span>/ {owners.length} SIGS</span>
            </div>
          </div>
          
          <div className="stat-box">
            <div className="stat-title">Protocol Activity</div>
            <div className="stat-val">
              {transactions.length} <span>EVENTS</span>
            </div>
          </div>
        </div>

        {/* Visuals Row: Chart & Owners */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '1.5rem', marginBottom: '1.5rem' }}>
          <div style={{ flex: 2, minWidth: '60%' }}>
            <ActivityChart transactions={transactions} />
          </div>
          <div style={{ flex: 1, minWidth: '30%' }}>
            <OwnersList owners={owners} account={account} />
          </div>
        </div>

        {/* Core Actions Row: Propose & List */}
        <div className="layout-split fade-up d-3">
          {isOwner ? (
            <section>
              <SubmitTransaction contract={contract} fetchTransactions={fetchWalletDetails} />
            </section>
          ) : (
            <div className="glass-card" style={{ textAlign: 'center', padding: '4rem 2rem' }}>
              <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="var(--border-highlight)" strokeWidth="1" style={{ marginBottom: '1.5rem' }}>
                <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
              </svg>
              <h3 style={{ color: 'var(--text-muted)', marginBottom: '0.5rem' }}>Observer Mode</h3>
              <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem' }}>Read-only access granted. Only designated signers can propose transactions.</p>
            </div>
          )}
          
          <section>
            <TransactionList 
              transactions={transactions} 
              contract={contract} 
              account={account} 
              fetchTransactions={fetchWalletDetails} 
              isOwner={isOwner}
            />
          </section>
        </div>
      </div>
    </>
  );
};

export default Dashboard;
