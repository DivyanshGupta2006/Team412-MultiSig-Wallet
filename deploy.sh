#!/bin/bash

# Exit script immediately if a command fails
set -e

echo "=== MultiSig Wallet Deployment Script ==="

# 1. Load environment variables
if [ -f .env ]; then
    echo "Loading .env file..."
    source .env
else
    echo "Error: .env file not found in the current directory."
    exit 1
fi

# 2. Determine target network (default to sepolia)
NETWORK=${1:-sepolia}

if [ "$NETWORK" == "local" ]; then
    echo "Deploying to local Anvil network..."
    
    forge script script/deploy.s.sol \
        --rpc-url http://127.0.0.1:8545 \
        --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
        --broadcast

elif [ "$NETWORK" == "sepolia" ]; then
    echo "Deploying to Sepolia testnet..."
    
    # Clean potential Windows carriage returns (\r)
    SEPOLIA_RPC_URL="${SEPOLIA_RPC_URL%$'\r'}"
    PRIVATE_KEY="${PRIVATE_KEY%$'\r'}"
    ETHERSCAN_API_KEY="${ETHERSCAN_API_KEY%$'\r'}"

    # Check if critical Sepolia variables are present
    if [ -z "$SEPOLIA_RPC_URL" ] || [ -z "$PRIVATE_KEY" ] || [ -z "$ETHERSCAN_API_KEY" ]; then
        echo "Error: Missing SEPOLIA_RPC_URL, PRIVATE_KEY, or ETHERSCAN_API_KEY in .env file."
        exit 1
    fi
    
    # Ensure PRIVATE_KEY starts with 0x
    FORMATTED_KEY="0x${PRIVATE_KEY#0x}"

    forge script script/deploy.s.sol \
        --rpc-url "$SEPOLIA_RPC_URL" \
        --private-key "$FORMATTED_KEY" \
        --broadcast \
        --verify \
        --etherscan-api-key "$ETHERSCAN_API_KEY"

else
    echo "Unknown network: $NETWORK"
    echo "Usage: ./deploy.sh [local|sepolia]"
    echo "If no network is specified, 'sepolia' is used by default."
    exit 1
fi

echo "Deployment finished successfully!"
