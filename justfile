# This justfile requires https://github.com/casey/just

mod bitcoin
mod cln
mod lnd

# Load environment variables from `.env` file.
set dotenv-load
# Fail the script if the env file is not found.
set dotenv-required

project_dir := justfile_directory()

lnd0_container_name := 'regtest_lnd_tier0_geodata'
lnd0_lightning_port := '9735'
lnd1_container_name := 'regtest_lnd_tier1_project_owner'
lnd1_lightning_port := '9735'
lnd2_container_name := 'regtest_lnd_tier1_company'
lnd2_lightning_port := '9735'
lnd3_container_name := 'regtest_lnd_tier1_supervision'
lnd3_lightning_port := '9735'
lnd4_container_name := 'regtest_lnd_tier2_geodata'
lnd4_lightning_port := '9735'

cln0_container_name := 'regtest_cln0_monitor'
cln0_lightning_port := '19846'

# print available targets
[group("project-agnostic")]
default:
  @just --list --justfile {{justfile()}}

# evaluate and print all just variables
[group("project-agnostic")]
evaluate:
  @just --evaluate

# print system information such as OS and architecture
[group("project-agnostic")]
system-info:
  @echo "architecture: {{arch()}}"
  @echo "os: {{os()}}"
  @echo "os family: {{os_family()}}"

# checks if docker and docker compose is installed and running
[private]
[group("setup")]
check-deps:
  @just check-docker
  @just check-jq

# checks if jq is installed
[private]
[group("setup")]
check-jq:
  #!/usr/bin/env bash
  if ! command -v jq &> /dev/null; then
    >&2 echo 'Error: jq is not installed.';
    exit 1;
  fi

# checks if docker and docker compose is installed and running
[private]
[group("setup")]
check-docker:
  #!/usr/bin/env bash
  if ! command -v docker &> /dev/null; then
    >&2 echo 'Error: Docker is not installed.';
    exit 1;
  fi

  if ! command -v docker compose &> /dev/null; then
   >&2 echo 'Error: Docker Compose is not installed.' >&2;
   exit 1;
  fi

  if ! command docker info &> /dev/null; then
    >&2 echo 'Error: Docker is not running.';
    exit 1;
  fi

# Execute a command in a running container
[group("docker")]
docker-exec +command: check-docker
  @docker compose --file ./docker-compose.yml {{command}}

# Create and start containers
[group("docker")]
up *args='':
  @just docker-exec up --detach --wait --wait-timeout 120 {{args}}

# Stop containers
[group("docker")]
down *args='':
  @just docker-exec down {{args}}

# Stop and remove containers, networks and volumes
[group("docker")]
clean:
  @just down --remove-orphans --volumes

# Build or rebuild services
[group("docker")]
build *args='':
  @just docker-exec build {{args}}

# Rebuild services without cache
[group("docker")]
rebuild *args='':
  @just build --no-cache {{args}}

# View and follow output from containers
[group("docker")]
logs *args='':
  @just docker-exec logs --follow {{args}}

# List containers
[group("docker")]
ps *args='':
  @just docker-exec ps {{args}}

# Execute a command on instance "cln0"
[group("cln0")]
cln0-exec +command:
  @just cln::exec {{cln0_container_name}} {{command}}

[private]
[group("cln0")]
cln0-waitblockheight blockheight timeout='5':
  @just cln0-exec --keywords waitblockheight "blockheight"={{blockheight}} "timeout"={{timeout}}

# Execute a command on instance "lnd0"
[group("lnd0")]
lnd0-exec +command:
  @just lnd::exec {{lnd0_container_name}} {{command}}

# Execute a command on instance "lnd1"
[group("lnd1")]
lnd1-exec +command:
  @just lnd::exec {{lnd1_container_name}} {{command}}

# Execute a command on instance "lnd2"
[group("lnd2")]
lnd2-exec +command:
  @just lnd::exec {{lnd2_container_name}} {{command}}

# Execute a command on instance "lnd3"
[group("lnd3")]
lnd3-exec +command:
  @just lnd::exec {{lnd3_container_name}} {{command}}

# Execute a command on instance "lnd4"
[group("lnd4")]
lnd4-exec +command:
  @just lnd::exec {{lnd4_container_name}} {{command}}


[private]
[group("lnd0")]
lnd0-id:
  @just lnd::id {{lnd0_container_name}}

[private]
[group("lnd1")]
lnd1-id:
  @just lnd::id {{lnd1_container_name}}

[private]
[group("lnd2")]
lnd2-id:
  @just lnd::id {{lnd2_container_name}}

[private]
[group("lnd3")]
lnd3-id:
  @just lnd::id {{lnd3_container_name}}
  
[private]
[group("lnd4")]
lnd4-id:
  @just lnd::id {{lnd4_container_name}}

[private]
[group("lnd4")]
lnd4-fundchannel-cln3 amount_sat='4194303' push_sat='2097151':
  #!/usr/bin/env bash
  set -euxo pipefail
  just lnd::openchannel {{lnd4_container_name}} $(just cln3-id) {{amount_sat}} {{push_sat}}

[group("lnd4")]
lnd4-getinfo:
  @just lnd4-exec getinfo

[private]
[group("setup")]
setup-fund-wallets:
  #!/usr/bin/env bash
  set -euxo pipefail
  just bitcoin::mine 1 $(just lnd::newaddr {{lnd0_container_name}})
  just bitcoin::mine 2 $(just lnd::newaddr {{lnd1_container_name}})
  just bitcoin::mine 2 $(just lnd::newaddr {{lnd2_container_name}})
  just bitcoin::mine 2 $(just lnd::newaddr {{lnd3_container_name}})
  just bitcoin::mine 1 $(just lnd::newaddr {{lnd4_container_name}})

[private]
[group("setup")]
setup-connect-peers:
  #!/usr/bin/env bash
  set -euxo pipefail
  just lnd::connect {{lnd0_container_name}} $(just lnd1-id) {{lnd1_container_name}} {{lnd1_lightning_port}}
  just lnd::connect {{lnd0_container_name}} $(just lnd2-id) {{lnd2_container_name}} {{lnd2_lightning_port}}
  just lnd::connect {{lnd0_container_name}} $(just lnd3-id) {{lnd3_container_name}} {{lnd3_lightning_port}}
  just lnd::connect {{lnd4_container_name}} $(just lnd1-id) {{lnd1_container_name}} {{lnd1_lightning_port}}
  just lnd::connect {{lnd4_container_name}} $(just lnd2-id) {{lnd2_container_name}} {{lnd2_lightning_port}}
  just lnd::connect {{lnd4_container_name}} $(just lnd3-id) {{lnd3_container_name}} {{lnd3_lightning_port}}

[private]
[group("setup")]
setup-create-channels:
  @just cln0-fundchannel-cln1
  @just cln0-fundchannel-cln2
  @just cln2-fundchannel-cln3
  @just cln3-fundchannel-cln5
  @just lnd4-fundchannel-cln3

# Send payments back and forth between lnd0<->lnd1<->lnd4
[private]
[group("health")]
probe-payment-lnd0-lnd1-lnd4:
  #!/usr/bin/env bash
  set -euxo pipefail
  # lnd0<->lnd1<->lnd4
  ## lnd4->lnd-1->lnd0
  INVOICE0_LABEL=$(printf "healthcheck_%s" "$(uuidgen -t)")
  INVOICE0_BOLT11=$(just lnd::create-invoice {{lnd0_container_name}} 1000 | jq --raw-output .payment_request)
  just lnd::exec {{lnd4_container_name}} sendpayment --force --pay_req="${INVOICE0_BOLT11}"
  ## lnd0->lnd-1->lnd4
  INVOICE1_BOLT11=$(just lnd::create-invoice {{lnd4_container_name}} 1000 | jq --raw-output .payment_request)
  just lnd::exec {{lnd0_container_name}}sendpayment --force --pay_req="${INVOICE1_BOLT11}"
  echo "HEALTHCHECK SUCCESS (lnd0<->lnd1<->lnd4)."

# Send payments back and forth between cln0<->cln5 and cln1<->lnd4
[group("health")]
probe-payment:
  #!/usr/bin/env bash
  set -euxo pipefail
  while true; do
    just probe-payment-lnd0-lnd1-lnd4
    sleep 3
  done

# Initialize lightning; fund wallets, connect peers and create channels
[private]
[group("setup")]
init-lightning:
  @just bitcoin::mine 1
  @just cln0-waitblockheight 1
  @just setup-fund-wallets # mines 8 blocks; afterwards blockheight := 9
  @just bitcoin::mine 100
  @just cln0-waitblockheight 109
  #@just setup-connect-peers
  #@just setup-create-channels
  @just bitcoin::mine 6
  @just cln0-waitblockheight 115
  @just bitcoin::mine 6
  @just cln0-waitblockheight 121
  @just bitcoin::mine 10
  @just cln0-waitblockheight 131
  @just bitcoin::mine 1
  @just cln0-waitblockheight 132

# Initialize setup; setup lightning infra and ebill data
[group("setup")]
init: check-deps
  @just init-lightning

# Initialize setup; setup lightning infra and ebill data
[group("info")]
info:
  @echo "{{BOLD + BLACK + BG_WHITE + UNDERLINE}}# lightning-regtest-setup-devel{{NORMAL}}"
  @echo "{{BOLD + GREEN + UNDERLINE}}## bitcoin{{NORMAL}}"
  @just bitcoin::info

  @echo "{{BOLD + MAGENTA + UNDERLINE}}## lnd0{{NORMAL}}{{BOLD + MAGENTA}}"
  @just lnd0-id
  @echo "{{BOLD + MAGENTA}}lnd0 container name:{{NORMAL}} {{lnd0_container_name}}"
  @echo "{{BOLD + MAGENTA}}lnd0 rest endpoint:{{NORMAL}} https://localhost:10841"
  @echo "{{BOLD + MAGENTA}}lnd0 getinfo:{{NORMAL}}"
  @curl --silent --insecure https://localhost:10841/v1/getinfo \
    | jq '{version, identity_pubkey, alias, num_peers, num_pending_channels, num_active_channels, num_inactive_channels, block_height, chains}'

  @echo "{{BOLD + CYAN + UNDERLINE}}## lnd4{{NORMAL}}{{BOLD + CYAN}}"
  @just lnd4-id
  @echo "{{BOLD + CYAN}}lnd4 container name:{{NORMAL}} {{lnd4_container_name}}"
  @echo "{{BOLD + CYAN}}lnd4 rest endpoint:{{NORMAL}} https://localhost:14841"
  @echo "{{BOLD + CYAN}}lnd4 getinfo:{{NORMAL}}"
  @curl --silent --insecure https://localhost:14841/v1/getinfo \
    | jq '{version, identity_pubkey, alias, num_peers, num_pending_channels, num_active_channels, num_inactive_channels, block_height, chains}'
