#!/bin/bash

which npm > /dev/null
if [ "$?" -ne "0" ]; then
echo "node package manager (npm) missing. Please install node.js (http://nodejs.org)."
  exit 1
fi

echo "Installing dependencies..."

npm install coffee-script
npm install binary
