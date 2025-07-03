#!/bin/bash
set -e

# Simple initialization of externals directory
# Multiple containers can safely run this simultaneously since they're copying identical files

echo "Checking externals directory initialization..."

# If already initialized, we're done
if [ -f "/home/runner/externals/.initialized" ]; then
    echo "Externals directory already initialized"
else
    echo "Initializing externals directory..."
    
    # Copy toolcache from template if it exists and externals is empty/minimal
    if [ -d "/home/runner/externals-template" ] && [ "$(ls -A /home/runner/externals-template 2>/dev/null)" ]; then
        echo "Copying toolcache from template to mounted externals directory..."
        cp -r /home/runner/externals-template/* /home/runner/externals/ 2>/dev/null || true
        
        # Ensure proper ownership
        chown -R runner:docker /home/runner/externals/ 2>/dev/null || true
        
        echo "Externals initialization complete"
    else
        echo "Warning: externals-template directory not found or empty"
    fi
    
    # Mark initialization as complete
    touch "/home/runner/externals/.initialized"
fi

# Verify the toolcache is properly set up
if [ -f "/home/runner/externals/node20/bin/node" ]; then
    echo "Externals directory ready - Node.js toolcache verified"
else
    echo "Warning: Node.js toolcache not found at expected location"
fi