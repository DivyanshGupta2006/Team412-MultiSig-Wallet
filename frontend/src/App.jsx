import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import Login from './components/Login'
import Dashboard from './components/Dashboard'
import { getContract } from './utils/contract'

function App() {
  const [account, setAccount] = useState('')
  const [provider, setProvider] = useState(null)
  const [contract, setContract] = useState(null)
  const [isConnecting, setIsConnecting] = useState(false)
  const [loginError, setLoginError] = useState('')

  const checkConnection = async () => {
    if (window.ethereum) {
      try {
        const accounts = await window.ethereum.request({ method: 'eth_accounts' })
        if (accounts.length > 0) {
          setupConnection(accounts[0])
        }
      } catch (err) {
        console.error("Connection error:", err)
      }
    }
  }

  const connectWallet = async () => {
    if (!window.ethereum) {
      alert('Please install MetaMask to use this dApp!')
      return
    }

    try {
      setIsConnecting(true)
      const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' })
      await setupConnection(accounts[0])
    } catch (err) {
      console.error(err)
      alert('Failed to connect wallet')
    } finally {
      setIsConnecting(false)
    }
  }

  const setupConnection = async (selectedAccount) => {
    setLoginError('')
    const web3Provider = new ethers.BrowserProvider(window.ethereum)
    
    const signer = await web3Provider.getSigner()
    const multisigContract = getContract(signer)
    
    try {
      const isOwner = await multisigContract.isOwner(selectedAccount)
      if (!isOwner) {
        setLoginError('ACCESS DENIED: You are not an authorized owner of this Multi-Sig Wallet.')
        setIsConnecting(false)
        return
      }
    } catch (err) {
      console.error("Error checking owner status:", err)
      setLoginError('Network Error: Ensure you are connected to the Sepolia testnet.')
      setIsConnecting(false)
      return
    }

    setAccount(selectedAccount)
    setProvider(web3Provider)
    setContract(multisigContract)
  }

  const disconnectWallet = () => {
    setAccount('')
    setContract(null)
    setProvider(null)
  }

  useEffect(() => {
    checkConnection()
    
    if (window.ethereum) {
      window.ethereum.on('accountsChanged', (accounts) => {
        if (accounts.length > 0) {
          setupConnection(accounts[0])
        } else {
          setAccount('')
          setContract(null)
          setProvider(null)
        }
      })
      
      window.ethereum.on('chainChanged', () => {
        window.location.reload()
      })
    }
    
    return () => {
      if (window.ethereum) {
        window.ethereum.removeAllListeners('accountsChanged')
        window.ethereum.removeAllListeners('chainChanged')
      }
    }
  }, [])

  return (
    <>
      {!account ? (
        <Login connectWallet={connectWallet} isConnecting={isConnecting} loginError={loginError} />
      ) : (
        <Dashboard account={account} contract={contract} provider={provider} disconnectWallet={disconnectWallet} />
      )}
    </>
  )
}

export default App
