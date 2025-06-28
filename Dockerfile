FROM ghcr.io/catthehacker/ubuntu:act-22.04

# Label to automatically link package to this repository
LABEL org.opencontainers.image.source="https://github.com/handyshed/github-actions-custom-runner"
LABEL org.opencontainers.image.description="Custom GitHub Actions runner with pre-installed Playwright dependencies"

# Create user with UID 10001 (high enough to avoid conflicts with system users)
ARG USER_UID=10001
ARG USER_GID=10001

RUN groupadd -g ${USER_GID} ciuser && \
    useradd -m -u ${USER_UID} -g ciuser ciuser && \
    echo "ciuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Node.js if not already present (needed for npx)
# The base image might already have it, but we ensure it's available
RUN apt-get update && \
    apt-get install -y nodejs npm && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Playwright system dependencies (NOT the browsers themselves)
# This saves time during CI/CD runs as apt-get install is slow
# The actual browser binaries will be installed by each project's Playwright version
RUN npx -y playwright install-deps

# Set user and working directory
USER ciuser
WORKDIR /workspace
ENV HOME=/home/ciuser

# Ensure the workspace directory exists and has correct permissions
RUN sudo mkdir -p /workspace && sudo chown ciuser:ciuser /workspace