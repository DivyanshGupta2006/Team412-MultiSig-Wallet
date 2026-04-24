import React, { useEffect, useState } from 'react';

const Login = ({ connectWallet, isConnecting, loginError }) => {
  const [particles, setParticles] = useState([]);

  useEffect(() => {
    // Generate 30 random particles for the Antigravity background
    const newParticles = Array.from({ length: 30 }).map((_, i) => ({
      id: i,
      left: `${Math.random() * 100}%`,
      width: `${Math.random() * 4 + 1}px`,
      height: `${Math.random() * 4 + 1}px`,
      animationDuration: `${Math.random() * 10 + 10}s`,
      animationDelay: `${Math.random() * 5}s`,
    }));
    setParticles(newParticles);
  }, []);

  return (
    <div className="login-wrapper">
      {/* Antigravity Elegant Background Elements */}
      <div className="ag-canvas">
        {particles.map((p) => (
          <div 
            key={p.id} 
            className="ag-particle"
            style={{
              left: p.left,
              width: p.width,
              height: p.height,
              animationDuration: p.animationDuration,
              animationDelay: p.animationDelay
            }}
          ></div>
        ))}
      </div>

      <div className="ag-orbitals">
        <div className="ag-ring ag-ring-1"></div>
        <div className="ag-ring ag-ring-2"></div>
        <div className="ag-ring ag-ring-3"></div>
      </div>

      <div className="login-content fade-up">
        {/* Left Side: Elegant Branding & Features */}
        <div className="login-left fade-up d-1">
          <div className="brand-icon" style={{ width: '64px', height: '64px', borderRadius: '16px', marginBottom: '2rem' }}>
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <polygon points="12 2 2 7 12 12 22 7 12 2"></polygon>
              <polyline points="2 17 12 22 22 17"></polyline>
              <polyline points="2 12 12 17 22 12"></polyline>
            </svg>
          </div>
          
          <h1 style={{ fontSize: '4.5rem', lineHeight: '1.1', marginBottom: '1.5rem' }}>
            Multi Sig <span className="text-gradient-primary">Wallet</span>
          </h1>
          
          <p style={{ color: 'var(--text-muted)', fontSize: '1.25rem', maxWidth: '500px', fontWeight: '300', lineHeight: '1.7' }}>
            The gold standard for decentralized treasury management. Enforce M-of-N signature consensus to secure your digital assets against any single point of failure.
          </p>
          
          <div className="feature-list">
            <div className="feature-item">
              <div className="feature-icon">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>
              </div>
              <div>
                <h4 style={{ margin: 0, fontSize: '1.1rem', color: '#fff' }}>Enterprise Security</h4>
                <p style={{ margin: 0, fontSize: '0.9rem', color: 'var(--text-muted)' }}>Cryptographically secure multi-party computation.</p>
              </div>
            </div>
            
            <div className="feature-item">
              <div className="feature-icon">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polygon points="12 2 2 7 12 12 22 7 12 2"></polygon><polyline points="2 17 12 22 22 17"></polyline><polyline points="2 12 12 17 22 12"></polyline></svg>
              </div>
              <div>
                <h4 style={{ margin: 0, fontSize: '1.1rem', color: '#fff' }}>Decentralized Ledger</h4>
                <p style={{ margin: 0, fontSize: '0.9rem', color: 'var(--text-muted)' }}>Immutable, transparent, and unalterable history.</p>
              </div>
            </div>
          </div>
        </div>

        {/* Right Side: Glass Login Card */}
        <div className="login-right fade-up d-2">
          <div className="glass-card" style={{ maxWidth: '480px', width: '100%', textAlign: 'center' }}>
            <h2 style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>Welcome Back</h2>
            <p style={{ color: 'var(--text-muted)', marginBottom: '3rem', fontSize: '1.05rem' }}>Authenticate to access your secure vault.</p>
            
            {loginError && (
              <div style={{ padding: '1.2rem', background: 'rgba(255, 0, 85, 0.1)', color: 'var(--color-tertiary)', borderRadius: 'var(--radius-sm)', marginBottom: '2rem', border: '1px solid rgba(255, 0, 85, 0.3)', fontSize: '0.95rem', display: 'flex', alignItems: 'flex-start', gap: '0.75rem', textAlign: 'left', fontWeight: '500' }}>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ flexShrink: 0, marginTop: '2px' }}>
                  <circle cx="12" cy="12" r="10"></circle>
                  <line x1="12" y1="8" x2="12" y2="12"></line>
                  <line x1="12" y1="16" x2="12.01" y2="16"></line>
                </svg>
                {loginError}
              </div>
            )}
            
            <button 
              className="btn btn-glow" 
              onClick={connectWallet} 
              disabled={isConnecting}
              style={{ width: '100%', padding: '1.2rem', fontSize: '1.2rem', marginBottom: '2rem' }}
            >
              <span>
                {isConnecting ? (
                  <span style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', justifyContent: 'center' }}>
                    <span className="loader-ring"></span>
                    Authenticating...
                  </span>
                ) : (
                  'Connect Web3 Wallet'
                )}
              </span>
            </button>
            
            <p style={{ fontSize: '0.85rem', color: 'var(--text-muted)', borderTop: '1px solid rgba(255,255,255,0.05)', paddingTop: '1.5rem', margin: 0 }}>
              By connecting your wallet, you agree to our Terms of Service and Privacy Policy. Secure connection powered by Web3.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Login;
