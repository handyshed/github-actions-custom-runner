FROM ghcr.io/actions/actions-runner:latest

# Label to automatically link package to this repository
LABEL org.opencontainers.image.source="https://github.com/handyshed/github-actions-custom-runner"
LABEL org.opencontainers.image.description="Custom GitHub Actions runner with pre-installed Playwright dependencies"

# Switch to root for installation tasks
USER root

# Install Node.js 20 from NodeSource, and GitHub CLI
RUN apt-get update && \
    apt-get install -y \
    curl \
    gpg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
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

# Set up externals template system for host mounting
# Move built-in externals to template location, create empty externals for mounting
RUN mv /home/runner/externals /home/runner/externals-template && \
    mkdir -p /home/runner/externals && \
    chown runner:docker /home/runner/externals

# Copy initialization and entrypoint scripts
COPY init-externals.sh /usr/local/bin/init-externals.sh
COPY entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /usr/local/bin/init-externals.sh && \
    chmod +x /home/runner/entrypoint.sh

# Switch back to runner user and set working directory
USER runner
WORKDIR /home/runner

# Set the entrypoint
ENTRYPOINT ["/home/runner/entrypoint.sh"]