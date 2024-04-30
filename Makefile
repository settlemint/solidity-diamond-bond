# Makefile for Foundry Ethereum Development Toolkit

.PHONY: build test format snapshot anvil deploy deploy-anvil cast help subgraph clear-anvil-port

build:
	@echo "Building with Forge..."
	@forge build

test:
	@echo "Testing with Forge..."
	@forge test

format:
	@echo "Formatting with Forge..."
	@forge fmt

snapshot:
	@echo "Creating gas snapshot with Forge..."
	@forge snapshot

anvil:
	@echo "Starting Anvil local Ethereum node..."
	@make clear-anvil-port
	@anvil

deploy-anvil:
	@echo "Deploying to Anvil..."
	@forge script script/DeployDiamond.s.sol --sender 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url anvil --broadcast --unlocked

deploy-btp:
	@eval $$(curl -H "x-auth-token: $${BTP_SERVICE_TOKEN}" -s $${BTP_CLUSTER_MANAGER_URL}/ide/foundry/$${BTP_SCS_ID}/env | sed 's/^/export /'); \
	args=""; \
	if [ ! -z "$${BTP_FROM}" ]; then \
		args="--unlocked --sender $${BTP_FROM} --broadcast"; \
	else \
		echo "\033[1;33mWARNING: No keys are activated on the node, falling back to interactive mode...\033[0m"; \
		echo ""; \
		args="--interactive"; \
	fi; \
	if [ ! -z "$${BTP_GAS_PRICE}" ]; then \
		args="$$args --gas-price $${BTP_GAS_PRICE}"; \
	fi; \
	if [ "$${BTP_EIP_1559_ENABLED}" = "false" ]; then \
		args="$$args --legacy"; \
	fi; \
	forge script script/DeployDiamond.s.sol $${args} --rpc-url $${BTP_RPC_URL} --json

subgraph:
	@echo "Deploying the subgraph..."
	@rm -Rf subgraph/subgraph.config.json
	@CHAIN_ID=$$(cast chain-id --rpc-url $$BTP_RPC_URL); \
	output=$$(jq '.transactions[] | \
		select(.transactionType == "CREATE" and \
		(.contractName == "GenericToken" or .contractName == "Diamond")) | \
		if .contractName == "GenericToken" then \
			{contractName: "GenericToken", contractAddress: (.contractAddress // "not available"), transactionHash: (.hash // "not available")} \
		elif .contractName == "Diamond" then \
			{contractName: "Diamond", contractAddress: (.contractAddress // "not available"), transactionHash: (.hash // "not available")} \
		else empty end' broadcast/DeployDiamond.s.sol/$$CHAIN_ID/run-latest.json); \
	export DEPLOYED_ERC20_ADDRESS=$$(echo "$$output" | jq -r 'select(.contractName == "GenericToken") | .contractAddress'); \
	export TRANSACTION_HASH_ERC20=$$(echo "$$output" | jq -r 'select(.contractName == "GenericToken") | .transactionHash'); \
	export DEPLOYED_ADDRESS=$$(echo "$$output" | jq -r 'select(.contractName == "Diamond") | .contractAddress'); \
	export TRANSACTION_HASH=$$(echo "$$output" | jq -r 'select(.contractName == "Diamond") | .transactionHash'); \
	export BLOCK_NUMBER=$$(cast receipt --rpc-url $${BTP_RPC_URL} $${TRANSACTION_HASH} | grep "^blockNumber" | awk '{print $$2}'); \
	export BLOCK_NUMBER_ERC20=$$(cast receipt --rpc-url $${BTP_RPC_URL} $${TRANSACTION_HASH_ERC20} | grep "^blockNumber" | awk '{print $$2}'); \
	yq e -p=json -o=json '.datasources[0].address = strenv(DEPLOYED_ADDRESS) | .datasources[0].startBlock = strenv(BLOCK_NUMBER) | .datasources[1].address = strenv(DEPLOYED_ERC20_ADDRESS) | .datasources[1].startBlock = strenv(BLOCK_NUMBER_ERC20) | .chain = strenv(BTP_NODE_UNIQUE_NAME)' subgraph/subgraph.config.template.json > subgraph/subgraph.config.json; \

	@cd subgraph && npx graph-compiler --config subgraph.config.json --include node_modules/@openzeppelin/subgraphs/src/datasources ./datasources --export-schema --export-subgraph
	@cd subgraph && yq e '.specVersion = "0.0.4"' -i generated/solidity-diamond-bond.subgraph.yaml
	@cd subgraph && yq e '.description = "Solidity Token diamond-bond"' -i generated/solidity-diamond-bond.subgraph.yaml
	@cd subgraph && yq e '.repository = "https://github.com/settlemint/solidity-diamond-bond"' -i generated/solidity-diamond-bond.subgraph.yaml
	@cd subgraph && yq e '.features = ["nonFatalErrors", "fullTextSearch", "ipfsOnEthereumContracts"]' -i generated/solidity-diamond-bond.subgraph.yaml
	@cd subgraph && npx graph codegen generated/solidity-diamond-bond.subgraph.yaml
	@cd subgraph && npx graph build generated/solidity-diamond-bond.subgraph.yaml
	@eval $$(curl -H "x-auth-token: $${BTP_SERVICE_TOKEN}" -s $${BTP_CLUSTER_MANAGER_URL}/ide/foundry/$${BTP_SCS_ID}/env | sed 's/^/export /'); \
	if [ -z "$${BTP_MIDDLEWARE}" ]; then \
		echo "\033[1;31mERROR: You have not launched a graph middleware for this smart contract set, aborting...\033[0m"; \
		exit 1; \
	else \
		cd subgraph; \
		npx graph create --node $${BTP_MIDDLEWARE} $${BTP_SCS_NAME}; \
		npx graph deploy --version-label v1.0.$$(date +%s) --node $${BTP_MIDDLEWARE} --ipfs $${BTP_IPFS}/api/v0 $${BTP_SCS_NAME} generated/solidity-diamond-bond.subgraph.yaml; \
	fi

cast:
	@echo "Interacting with EVM via Cast..."
	@cast $(SUBCOMMAND)

help:
	@echo "Forge help..."
	@forge --help
	@echo "Anvil help..."
	@anvil --help
	@echo "Cast help..."
	@cast --help

clear-anvil-port:
	-fuser -k -n tcp 8545