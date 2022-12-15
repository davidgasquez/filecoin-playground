export FULLNODE_API_INFO := /dns/api.chain.love/wss

lite-node:
	lotus daemon --lite

setup-wallet:
	lotus wallet import wallet.key --as-default

node:
	aria2c -x8 https://snapshots.mainnet.filops.net/minimal/latest.zst
	zstd -d *.car.zst
	lotus daemon --import-snapshot *.car --halt-after-import
