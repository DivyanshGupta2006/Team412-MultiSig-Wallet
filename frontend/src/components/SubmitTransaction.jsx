import React, { useState } from 'react';
import { ethers } from 'ethers';

const SubmitTransaction = ({ contract, fetchTransactions }) => {
  const [to, setTo] = useState('');
  const [value, setValue] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!to || !value) {
      setError('Recipient and Amount are required.');
      return;
    }

    try {
      setError('');
      setIsSubmitting(true);
      
      const parsedValue = ethers.parseEther(value);
      const parsedData = '0x';

      const tx = await contract.submitTransaction(to, parsedValue, parsedData);
      await tx.wait();
      
      setTo('');
      setValue('');
      
      if (fetchTransactions) {
        await fetchTransactions();
      }
    } catch (err) {
      console.error(err);
      setError(err.reason || err.message || 'Transaction failed.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="glass-card" style={{ position: 'sticky', top: '7rem' }}>
      <h2 style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '2rem', fontSize: '1.5rem' }}>
        <div style={{ background: 'rgba(0, 240, 255, 0.1)', padding: '0.6rem', borderRadius: '12px', border: '1px solid rgba(0,240,255,0.2)' }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--color-secondary)" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <line x1="12" y1="5" x2="12" y2="19"></line>
            <line x1="5" y1="12" x2="19" y2="12"></line>
          </svg>
        </div>
        New Proposal
      </h2>
      
      {error && (
        <div style={{ padding: '1rem', background: 'rgba(255, 0, 85, 0.1)', color: 'var(--color-tertiary)', borderRadius: 'var(--radius-sm)', marginBottom: '1.5rem', border: '1px solid rgba(255, 0, 85, 0.3)', fontSize: '0.9rem', display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="12" y1="8" x2="12" y2="12"></line>
            <line x1="12" y1="16" x2="12.01" y2="16"></line>
          </svg>
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        <div className="form-group">
          <label className="form-label">Recipient Address</label>
          <input 
            type="text" 
            className="form-input" 
            placeholder="0x..." 
            value={to} 
            onChange={(e) => setTo(e.target.value)} 
          />
        </div>
        
        <div className="form-group">
          <label className="form-label">Amount (ETH)</label>
          <input 
            type="number" 
            step="any"
            className="form-input" 
            placeholder="0.00" 
            value={value} 
            onChange={(e) => setValue(e.target.value)} 
          />
        </div>
        
        <button type="submit" className="btn btn-glow" style={{ width: '100%', marginTop: '1rem' }} disabled={isSubmitting}>
          <span>
            {isSubmitting ? (
              <span style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                <span className="loader-ring" style={{ width: '20px', height: '20px', borderWidth: '2px' }}></span>
                Proposing...
              </span>
            ) : (
              'Submit to Network'
            )}
          </span>
        </button>
      </form>
    </div>
  );
};

export default SubmitTransaction;
