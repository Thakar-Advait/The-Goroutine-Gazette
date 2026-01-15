#!/bin/bash
# Script to run Jekyll with Ruby 4.0 compatibility patch

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Set RUBYOPT to require the compatibility patch before Ruby starts
export RUBYOPT="-r${SCRIPT_DIR}/.jekyll/ruby4_compat"

# Run Jekyll with bundle exec
bundle exec jekyll "$@"
