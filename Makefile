lite-node:
	FULLNODE_API_INFO=wss://api.chain.love lotus daemon --lite

setup-wallet:
	lotus wallet import wallet.key --as-default