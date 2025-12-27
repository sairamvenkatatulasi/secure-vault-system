#!/bin/sh
set -e

echo "Waiting for blockchain to be ready..."
sleep 15

echo "Deploying contracts..."
npx hardhat run scripts/deploy.js --network localhost

echo "Deployment complete!"
tail -f /dev/null
