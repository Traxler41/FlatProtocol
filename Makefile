# ================================
# CONFIG
# ================================

include .env

FOUNDRY_PROFILE ?= default

SEPOLIA_RPC_URL := $(SEPOLIA_RPC_URL)
MAINNET_RPC_URL := $(MAINNET_RPC_URL)
PRIVATE_KEY := $(PRIVATE_KEY)
ETHERSCAN_API_KEY := $(ETHERSCAN_API_KEY)

# ================================
# BUILD & TEST
# ================================

build:
	forge build

test:
	forge test -vv

test-v:
	forge test -vvv

clean:
	forge clean

format:
	forge fmt

# ================================
# LOCAL NODE (ANVIL)
# ================================

anvil:
	anvil

deploy-local:
	forge script script/Deploy.s.sol \
	--rpc-url http://127.0.0.1:8545 \
	--private-key $(PRIVATE_KEY) \
	--broadcast

# ================================
# SEPOLIA DEPLOY
# ================================

deploy-sepolia:
	forge script script/Deploy.s.sol \
	--rpc-url $(SEPOLIA_RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--broadcast \
	--verify \
	--etherscan-api-key $(ETHERSCAN_API_KEY) \
	-vvv

interact-sepolia:
	forge script script/Interactions.s.sol \
	--rpc-url $(SEPOLIA_RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--broadcast \
	-vvv

# ================================
# MAINNET DEPLOY (⚠️ REAL MONEY)
# ================================

deploy-mainnet:
	forge script script/Deploy.s.sol \
	--rpc-url $(MAINNET_RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--broadcast \
	--verify \
	--etherscan-api-key $(ETHERSCAN_API_KEY) \
	-vvv

interact-mainnet:
	forge script script/Interactions.s.sol \
	--rpc-url $(MAINNET_RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--broadcast \
	-vvv

# ================================
# HELP
# ================================

help:
	@echo "Available commands:"
	@echo " make build              - Compile contracts"
	@echo " make test               - Run tests"
	@echo " make test-v             - Verbose tests"
	@echo " make clean              - Clean build"
	@echo " make format             - Format code"
	@echo " make anvil              - Start local node"
	@echo " make deploy-local       - Deploy to local Anvil"
	@echo " make deploy-sepolia     - Deploy to Sepolia"
	@echo " make interact-sepolia   - Run interaction script on Sepolia"
	@echo " make deploy-mainnet     - Deploy to Mainnet (REAL FUNDS)"
	@echo " make interact-mainnet   - Interact on Mainnet"