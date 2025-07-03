#!/bin/bash
set -e

# Thread-safe initialization of externals directory using mkdir-based atomic locking
# This script safely copies the built-in toolcache to the host-mounted externals directory

echo "Checking externals directory initialization..."

# Try to create lock directory atomically
if mkdir "/home/runner/externals/.initializing" 2>/dev/null; then
    echo "Acquired initialization lock - initializing externals directory..."
    
    # We got the exclusive lock - initialize the directory
    if [ -d "/home/runner/externals-template" ]; then
        echo "Copying toolcache from template to mounted externals directory..."
        cp -r /home/runner/externals-template/* /home/runner/externals/
        
        # Ensure proper ownership
        chown -R runner:docker /home/runner/externals/
        
        # Mark initialization as complete
        touch "/home/runner/externals/.initialized"
        echo "Externals initialization complete"
    else
        echo "Warning: externals-template directory not found"
        touch "/home/runner/externals/.initialized"
    fi
    
    # Release the lock
    rmdir "/home/runner/externals/.initializing"
    echo "Released initialization lock"
    
elif [ -f "/home/runner/externals/.initialized" ]; then
    echo "Externals directory already initialized"
    
else
    # Another container is initializing - wait for completion
    echo "Another container is initializing externals, waiting..."
    
    # Wait for initialization to complete (with timeout)
    timeout=60  # 60 seconds timeout
    elapsed=0
    
    while [ ! -f "/home/runner/externals/.initialized" ] && [ $elapsed -lt $timeout ]; do
        sleep 1
        elapsed=$((elapsed + 1))
        
        if [ $((elapsed % 10)) -eq 0 ]; then
            echo "Still waiting for externals initialization... (${elapsed}s)"
        fi
    done
    
    if [ -f "/home/runner/externals/.initialized" ]; then
        echo "Externals initialization completed by another container"
    else
        echo "Error: Timeout waiting for externals initialization"
        exit 1
    fi
fi

# Verify the toolcache is properly set up
if [ -f "/home/runner/externals/node20/bin/node" ]; then
    echo "Externals directory ready - Node.js toolcache verified"
else
    echo "Warning: Node.js toolcache not found at expected location"
fi