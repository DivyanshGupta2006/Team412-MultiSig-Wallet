import React from 'react';
import { ethers } from 'ethers';

const ActivityChart = ({ transactions }) => {
  let dataPoints = transactions.map(tx => Number(ethers.formatEther(tx.value)));
  
  if (dataPoints.length === 0) {
    return (
      <div className="glass-card fade-up d-1" style={{ padding: '2rem', height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', minHeight: '300px' }}>
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth="1" style={{ marginBottom: '1rem' }}>
          <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>
        </svg>
        <h3 style={{ color: 'var(--text-muted)', margin: 0 }}>No Volume Data</h3>
        <p style={{ color: 'var(--text-muted)', fontSize: '0.85rem', marginTop: '0.5rem' }}>Awaiting first transaction...</p>
      </div>
    );
  } else if (dataPoints.length === 1) {
    // Duplicate the single point so we can draw a flat line across the chart
    dataPoints = [dataPoints[0], dataPoints[0]];
  }

  const width = 800;
  const height = 200;
  const padding = 20;
  
  const maxVal = Math.max(...dataPoints, 0.1);
  const minVal = 0;
  
  const points = dataPoints.map((val, i) => {
    const x = padding + (i / (dataPoints.length - 1)) * (width - padding * 2);
    const y = height - padding - ((val - minVal) / (maxVal - minVal)) * (height - padding * 2);
    return `${x},${y}`;
  });

  const pathD = `M ${points.join(' L ')}`;
  
  const areaD = `${pathD} L ${width - padding},${height - padding} L ${padding},${height - padding} Z`;

  return (
    <div className="glass-card fade-up d-1" style={{ padding: '2rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
        <h3 style={{ fontSize: '1.2rem', display: 'flex', alignItems: 'center', gap: '0.5rem', margin: 0 }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--color-primary)" strokeWidth="2">
            <polyline points="22 12 18 12 15 21 9 3 6 12 2 12"></polyline>
          </svg>
          Volume History
        </h3>
        <span className="tag tag-done" style={{ background: 'rgba(112, 0, 255, 0.1)', color: 'var(--color-primary)', border: '1px solid rgba(112, 0, 255, 0.3)' }}>
          All Time
        </span>
      </div>
      
      <div style={{ width: '100%', height: '220px', position: 'relative' }}>
        <svg viewBox={`0 0 ${width} ${height}`} style={{ width: '100%', height: '100%', overflow: 'visible' }}>
          <defs>
            <linearGradient id="lineGlow" x1="0" y1="0" x2="1" y2="0">
              <stop offset="0%" stopColor="var(--color-secondary)" />
              <stop offset="100%" stopColor="var(--color-primary)" />
            </linearGradient>
            
            <linearGradient id="areaGradient" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="var(--color-primary)" stopOpacity="0.4" />
              <stop offset="100%" stopColor="var(--color-primary)" stopOpacity="0" />
            </linearGradient>
            
            <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
              <feGaussianBlur stdDeviation="8" result="blur" />
              <feComposite in="SourceGraphic" in2="blur" operator="over" />
            </filter>
          </defs>
          
          <line x1={padding} y1={height - padding} x2={width - padding} y2={height - padding} stroke="rgba(255,255,255,0.1)" strokeWidth="1" strokeDasharray="4 4" />
          <line x1={padding} y1={(height - padding)/2} x2={width - padding} y2={(height - padding)/2} stroke="rgba(255,255,255,0.05)" strokeWidth="1" strokeDasharray="4 4" />
          <line x1={padding} y1={padding} x2={width - padding} y2={padding} stroke="rgba(255,255,255,0.05)" strokeWidth="1" strokeDasharray="4 4" />

          <path d={areaD} fill="url(#areaGradient)" />
          
          <path d={pathD} fill="none" stroke="url(#lineGlow)" strokeWidth="4" filter="url(#glow)" strokeLinejoin="round" strokeLinecap="round" />
          
          {points.map((pt, i) => {
            const [x, y] = pt.split(',');
            return (
              <circle key={i} cx={x} cy={y} r="6" fill="var(--bg-base)" stroke="var(--color-secondary)" strokeWidth="3" filter="url(#glow)">
                <animate attributeName="r" values="5;7;5" dur="3s" repeatCount="indefinite" begin={`${i * 0.5}s`} />
              </circle>
            );
          })}
        </svg>
      </div>
    </div>
  );
};

export default ActivityChart;
