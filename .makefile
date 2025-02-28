# Makefile for Funding Contract

# Load environment variables
include .env

# Default key
defaultKey ?= defaultKey
SEPOLIA_WALLET ?= SEPOLIA_WALLET

# Install dependencies
install:
	forge install

# Run tests
test:
	forge test -vvv

# Generate coverage report
coverage:
	forge coverage --report lcov


deploy-to-sepolia:
	forge script script/fundingScript.s.sol:FundingScript --rpc-url $(SEPOLIA_RPC) --account $(SEPOLIA_WALLET) --broadcast

# Deploy contract to anvil
deploy-to-anvil:
	forge script script/fundingScript.s.sol:FundingScript --rpc-url http://localhost:8545 --account $(defaultKey) --broadcast

# Format code
format:
	forge fmt

# Clean build artifacts
clean:
	forge clean

.PHONY: install test coverage deploy format clean defaultKey deploy-and-verify
