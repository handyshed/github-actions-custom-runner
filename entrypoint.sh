#!/bin/bash
set -e

# Check required environment variables
if [ -z "${RUNNER_URL}" ]; then
    echo "Error: RUNNER_URL environment variable is required"
    exit 1
fi

if [ -z "${RUNNER_TOKEN}" ]; then
    echo "Error: RUNNER_TOKEN environment variable is required"
    exit 1
fi

if [ -z "${RUNNER_NAME}" ]; then
    echo "Error: RUNNER_NAME environment variable is required"
    exit 1
fi

# Set default labels if not provided
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,Linux,X64,containerized}"

echo "Configuring GitHub Actions Runner..."
echo "URL: ${RUNNER_URL}"
echo "Name: ${RUNNER_NAME}"
echo "Labels: ${RUNNER_LABELS}"

# Configure the runner
./config.sh \
  --url "${RUNNER_URL}" \
  --token "${RUNNER_TOKEN}" \
  --name "${RUNNER_NAME}" \
  --labels "${RUNNER_LABELS}" \
  --unattended \
  --replace

echo "Starting GitHub Actions Runner..."

# Handle graceful shutdown
cleanup() {
    echo "Removing runner..."
    ./config.sh remove --token "${RUNNER_TOKEN}"
    exit 0
}

trap cleanup SIGTERM SIGINT

# Run the runner
./run.sh &

# Wait for the runner process
wait $!