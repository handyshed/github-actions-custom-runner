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

# Install GitHub CLI (gh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Playwright system dependencies (NOT the browsers themselves)
# This saves time during CI/CD runs as apt-get install is slow
# The actual browser binaries will be installed by each project's Playwright version
RUN npx -y playwright install-deps

# Install dependencies needed for GitHub Actions runner
RUN apt-get update && \
    apt-get install -y \
    curl \
    jq \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Download and extract GitHub Actions runner
# Using a specific version for reproducibility
ARG RUNNER_VERSION=2.325.0
ARG TARGETARCH
RUN mkdir -p /runner && \
    cd /runner && \
    if [ "$TARGETARCH" = "arm64" ]; then \
        RUNNER_ARCH="arm64"; \
    else \
        RUNNER_ARCH="x64"; \
    fi && \
    curl -o actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz -L \
    https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz && \
    tar xzf ./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz && \
    rm ./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz && \
    chown -R ciuser:ciuser /runner

# Create workspace directory with correct permissions before switching user
RUN mkdir -p /workspace && chown ciuser:ciuser /workspace

# Copy entrypoint script
COPY --chown=ciuser:ciuser entrypoint.sh /runner/entrypoint.sh
RUN chmod +x /runner/entrypoint.sh

# Set user and working directory
USER ciuser
WORKDIR /runner
ENV HOME=/home/ciuser

# Set the entrypoint
ENTRYPOINT ["/runner/entrypoint.sh"]