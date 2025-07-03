#!/bin/bash
set -e

# Thread-safe initialization of externals directory using mkdir-based atomic locking
# This script safely copies the built-in toolcache to the host-mounted externals directory

echo "Checking externals directory initialization..."

# Check if already initialized first
if [ -f "/home/runner/externals/.initialized" ]; then
    echo "Externals directory already initialized"
    
# Try to create lock directory atomically
elif mkdir "/home/runner/externals/.initializing" 2>/dev/null; then
    echo "Acquired initialization lock - initializing externals directory..."
    
    # Double-check we still need to initialize (race condition protection)
    if [ ! -f "/home/runner/externals/.initialized" ]; then
        # We got the exclusive lock - initialize the directory
        if [ -d "/home/runner/externals-template" ] && [ "$(ls -A /home/runner/externals-template 2>/dev/null)" ]; then
            echo "Copying toolcache from template to mounted externals directory..."
            cp -r /home/runner/externals-template/* /home/runner/externals/ 2>/dev/null || true
            
            # Ensure proper ownership
            chown -R runner:docker /home/runner/externals/ 2>/dev/null || true
            
            echo "Externals initialization complete"
        else
            echo "Warning: externals-template directory not found or empty"
        fi
        
        # Mark initialization as complete (do this last)
        touch "/home/runner/externals/.initialized"
    else
        echo "Externals directory was initialized by another container during lock acquisition"
    fi
    
    # Release the lock
    rmdir "/home/runner/externals/.initializing" 2>/dev/null || true
    echo "Released initialization lock"
    
else
    # Another container is initializing - wait for completion
    echo "Another container is initializing externals, waiting..."
    
    # Wait for initialization to complete (with timeout)
    timeout=60  # 60 seconds timeout
    elapsed=0
    
    while [ ! -f "/home/runner/externals/.initialized" ] && [ $elapsed -lt $timeout ]; do
        # Check if lock directory still exists (initializer might have failed)
        if [ ! -d "/home/runner/externals/.initializing" ]; then
            echo "Lock directory disappeared, retrying initialization..."
            exec "$0"  # Restart the script
        fi
        
        sleep 1
        elapsed=$((elapsed + 1))
        
        if [ $((elapsed % 5)) -eq 0 ]; then
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