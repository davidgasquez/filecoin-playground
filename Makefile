export FULLNODE_API_INFO := /dns/api.chain.love/wss

lite-node:
	lotus daemon --lite

setup-wallet:
	lotus wallet import wallet.key --as-default
