-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEPLOYER_ANVIL_KEY:= 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

all: clean remove install update build

clean  :; forge clean

remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install:; forge install foundry-rs/forge-std --no-commit && forge install OpenZeppelin/openzeppelin-contracts --no-commit

update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

deploy:
	@forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --private-key $(DEPLOYER_ANVIL_KEY) --broadcast

deploySepolia : 
	@forge script script/Deploy.s.sol:Deploy --rpc-url sepolia --sender ${DEPLOYER_ADDRESS} --account deployer --broadcast --verify -vvvv

deployArbitrum : 
	@forge script script/Deploy.s.sol:Deploy --rpc-url arbitrum --sender ${DEPLOYER_ADDRESS} --account deployer --broadcast --verify -vvvv