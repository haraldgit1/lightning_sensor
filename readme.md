lightning-regtest-setup-devel
===

## Development

### Requirements
- docker compose (v2.32.1)
- jq (>=1.7.1)
- just (>=1.38.0)

### Clone
```
git clone https://github.com/theborakompanioni/lightning-regtest-setup-devel
```

### Typical workflow
```bash
just up
just init
just probe-payment # loops indefinitely
just probe-keysend # loops indefinitely
[...]
just clean
```

#### `getinfo`
```shell
just getinfo
```
```shell
## bitcoin
# bitcoin
bitcoin container name: regtest_bitcoind
bitcoin container rpcport: 18443
Chain: regtest
Blocks: 132
Headers: 132
Verification progress: 100.0000%
Difficulty: 4.656542373906925e-10

Network: in 0, out 0, total 0
Version: 270000
Time offset (s): 0
Proxies: n/a
Min tx relay fee rate (BTC/kvB): 0.00001000

Warnings: (none)
## lnd0
0210d2d7afe5a33f66d77e391417015e008bed2a2be4243a1f3c09b7d10be20ae8
lnd0 container name: regtest_lnd_tier0_geodata
lnd0 rest endpoint: https://localhost:10841
lnd0 getinfo:
{
  "version": "0.18.5-beta commit=v0.18.5-beta",
  "identity_pubkey": "0210d2d7afe5a33f66d77e391417015e008bed2a2be4243a1f3c09b7d10be20ae8",
  "alias": "lnd_tier0_geodata",
  "num_peers": 3,
  "num_pending_channels": 0,
  "num_active_channels": 3,
  "num_inactive_channels": 0,
  "block_height": 132,
  "chains": [
    {
      "chain": "bitcoin",
      "network": "regtest"
    }
  ]
}
## lnd4
03eaf815593ee59b84e94bb0f9f52e93f7fb48ab088aab2b6b8df8d7ffd92ef0a2
lnd4 container name: regtest_lnd_tier2_geodata
lnd4 rest endpoint: https://localhost:14841
lnd4 getinfo:
{
  "version": "0.18.5-beta commit=v0.18.5-beta",
  "identity_pubkey": "03eaf815593ee59b84e94bb0f9f52e93f7fb48ab088aab2b6b8df8d7ffd92ef0a2",
  "alias": "lnd_tier2_geodata",
  "num_peers": 3,
  "num_pending_channels": 0,
  "num_active_channels": 3,
  "num_inactive_channels": 0,
  "block_height": 132,
  "chains": [
    {
      "chain": "bitcoin",
      "network": "regtest"
    }
  ]
}
```

#### `listbalances`
```shell
just listbalances
```
```shell
## lnd0
0251cea2f33486dd2f8dcd8c2b27b6d6e843ee8ba5b55960c15ee200dfc22b583d
lnd0 balance/channels:
{
  "balance": "6291453",
  "pending_open_balance": "0",
  "local_balance": {
    "sat": "6291453",
    "msat": "6291453000"
  },
  "remote_balance": {
    "sat": "6281046",
    "msat": "6281046000"
  }
}
## lnd4
02eedb781093e5acd0148eb29220ff460f1126376054fad69a11147d3eb0f10811
lnd4 balance/channels:
{
  "balance": "6291453",
  "pending_open_balance": "0",
  "local_balance": {
    "sat": "6291453",
    "msat": "6291453000"
  },
  "remote_balance": {
    "sat": "6281046",
    "msat": "6281046000"
  }
}
```


#### Bitcoin

##### Mining
Mine a single block:
```shell
just bitcoin mine
```

Mine 100 blocks:
```shell
just bitcoin mine 100
```

Mine 1 block to a specific address:
```shell
just bitcoin mine 1 bcrt1qrnz0thqslhxu86th069r9j6y7ldkgs2tzgf5wx
```


## Lightning Network Regtest Setup
### Nodes

#### LND 0 (lnd_tier0_geodata)
#### LND 1 (lnd_tier1_project_owner)
#### LND 2 (lnd_tier1_company)
#### LND 3 (lnd_tier1_supervision)
#### LND 4 (lnd_tier2_geodata)

#### CLN 0 (cln0_monitor)
The lightning node just for monitoring the setup.

### Channels
```mermaid
flowchart TB
   lnd_tier0_geodata["Geodata 0 (lnd0)"]
   lnd_tier1_project_owner["Project Owner (lnd1)"]
   lnd_tier1_company["Company (lnd2)"]
   lnd_tier1_supervision["Supervision (lnd3)"]
   lnd_tier2_geodata["Geodata 1 (lnd4)"]
   cln0_monitor["Monitor (cln0)"]
   lnd_tier0_geodata <-->|4_194_303 sat| lnd_tier1_project_owner
   lnd_tier0_geodata <-->|4_194_303 sat| lnd_tier1_company
   lnd_tier0_geodata <-->|4_194_303 sat| lnd_tier1_supervision
   lnd_tier1_project_owner <-->|4_194_303 sat| lnd_tier2_geodata
   lnd_tier1_company <-->|4_194_303 sat| lnd_tier2_geodata
   lnd_tier1_supervision <-->|4_194_303 sat| lnd_tier2_geodata
   lnd_tier0_geodata ~~~ cln0_monitor
   lnd_tier1_project_owner ~~~ cln0_monitor
   lnd_tier1_company ~~~ cln0_monitor
   lnd_tier1_supervision ~~~ cln0_monitor
   lnd_tier2_geodata ~~~ cln0_monitor
```


## Resources
- LND API docs: https://lightning.engineering/api-docs/api/lnd/
- Mermaid Flowchart: https://mermaid.js.org/syntax/flowchart.html
