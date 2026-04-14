#!/usr/bin/env bash

# Exit if anything fails.
set -eo pipefail

# Change directory to project root
SCRIPT_PATH="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_PATH/.." || exit

# Utilities
GREEN="\033[00;32m"

function log () {
  echo -e "$1"
  echo "################################################################################"
  echo "#### $2 "
  echo "################################################################################"
  echo -e "\033[0m"
}

function main () {
    log $GREEN "Syncing specifications"

    # Clone specs repo and copy interface specs
    git clone --depth 1 https://github.com/tempoxyz/tempo.git specs
    cp -r specs/tips/ref-impls/src/interfaces src
    rm -rf specs

    # Remove redundant files
    rm -f src/interfaces/IERC20.sol

    # Format the code
    forge fmt

    log $GREEN "Done"
}

main