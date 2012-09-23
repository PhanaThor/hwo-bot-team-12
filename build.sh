#!/bin/bash

set -e

if ! which npm &> /dev/null; then
    echo "node package manager (npm) missing. Please install node.js (http://nodejs.org)." >&2
    exit 1
fi

mkdir -p log .tmp

echo "Installing dependencies..."
npm install binary
