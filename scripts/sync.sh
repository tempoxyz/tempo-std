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
    rm -rf src/interfaces
    git clone --depth 1 git@github.com:tempoxyz/docs.git specs
    cp -r specs/specs/src/interfaces src
    rm -rf specs

    # Format the code
    forge fmt

    log $GREEN "Done"
}

main