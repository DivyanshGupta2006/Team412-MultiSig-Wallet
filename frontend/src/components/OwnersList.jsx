import React from 'react';

const OwnersList = ({ owners, account }) => {
  return (
    <div className="glass-card fade-up d-2" style={{ padding: '2rem', height: '100%' }}>
      <h3 style={{ fontSize: '1.2rem', display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1.5rem', marginTop: 0 }}>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--color-secondary)" strokeWidth="2">
          <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
          <circle cx="9" cy="7" r="4"></circle>
          <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
          <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
        </svg>
        Authorized Signers
      </h3>
      
      <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
        {owners.map((owner, index) => {
          const isMe = owner.toLowerCase() === account.toLowerCase();
          
          const colorHue = parseInt(owner.substring(2, 6), 16) % 360;
          
          return (
            <div key={index} style={{ 
              display: 'flex', 
              alignItems: 'center', 
              gap: '1rem', 
              padding: '1rem', 
              background: isMe ? 'rgba(0, 229, 255, 0.05)' : 'rgba(255,255,255,0.02)',
              border: isMe ? '1px solid rgba(0, 229, 255, 0.2)' : '1px solid rgba(255,255,255,0.05)',
              borderRadius: '16px',
              transition: 'var(--transition-fast)'
            }}>
              <div style={{ 
                width: '40px', 
                height: '40px', 
                borderRadius: '10px', 
                background: `linear-gradient(135deg, hsl(${colorHue}, 80%, 60%), hsl(${(colorHue + 60) % 360}, 80%, 40%))`,
                boxShadow: `0 0 15px hsl(${colorHue}, 80%, 50%, 0.4)`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontFamily: 'var(--font-display)',
                fontWeight: 'bold',
                fontSize: '1.2rem'
              }}>
                {owner.substring(2, 4).toUpperCase()}
              </div>
              
              <div style={{ flex: 1, overflow: 'hidden' }}>
                <div style={{ fontFamily: 'var(--font-display)', fontSize: '0.9rem', color: '#fff' }}>
                  {owner.substring(0, 8)}...{owner.substring(36)}
                </div>
                <div style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
                  Signer #{index + 1}
                </div>
              </div>
              
              {isMe && (
                <span className="owner-badge" style={{ background: 'var(--color-secondary)', color: '#000', borderColor: 'var(--color-secondary)' }}>
                  YOU
                </span>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default OwnersList;
