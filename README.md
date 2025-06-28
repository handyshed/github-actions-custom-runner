# GitHub Actions Custom Runner Image

Self-contained Docker image for GitHub Actions self-hosted runners with pre-installed Playwright dependencies. Each container automatically registers itself as a runner and includes all necessary binaries.

## Features

- **Self-contained**: GitHub Actions runner binary included in the image
- **Auto-registration**: Containers register themselves using environment variables
- **Playwright-ready**: Pre-installed system dependencies for all Playwright browsers
- **Isolated**: Each container maintains its own cache and state
- **Scalable**: Run multiple containers for parallel job execution
- **Ephemeral**: Containers are stateless by default (optional persistent volumes)

## Quick Start

### Single Runner

```bash
docker run -d \
  --name github-runner \
  -e RUNNER_URL="https://github.com/YOUR_ORG/YOUR_REPO" \
  -e RUNNER_TOKEN="YOUR_REGISTRATION_TOKEN" \
  -e RUNNER_NAME="docker-runner-1" \
  -e RUNNER_LABELS="self-hosted,Linux,X64,containerized" \
  ghcr.io/handyshed/github-actions-runner:latest
```

### Multiple Runners with Docker Compose

1. Create a `.env` file:
```bash
RUNNER_URL=https://github.com/YOUR_ORG/YOUR_REPO
RUNNER_TOKEN=YOUR_REGISTRATION_TOKEN
```

2. Start the runners:
```bash
docker-compose up -d
```

This will start 3 runners by default. Scale as needed:
```bash
docker-compose up -d --scale runner-1=5
```

## Environment Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `RUNNER_URL` | GitHub organization or repository URL | Yes | - |
| `RUNNER_TOKEN` | Registration token from GitHub | Yes | - |
| `RUNNER_NAME` | Unique name for this runner | Yes | - |
| `RUNNER_LABELS` | Comma-separated list of labels | No | `self-hosted,Linux,X64,containerized` |

## Getting a Registration Token

### For a Repository
1. Go to Settings → Actions → Runners
2. Click "New self-hosted runner"
3. Copy the token from the configuration instructions

### For an Organization
1. Go to Organization Settings → Actions → Runners
2. Click "New runner"
3. Copy the token from the configuration instructions

### Using GitHub CLI
```bash
# For a repository
gh api repos/OWNER/REPO/actions/runners/registration-token --jq .token

# For an organization
gh api orgs/ORG/actions/runners/registration-token --jq .token
```

## Container Details

### Base Image
- `ghcr.io/catthehacker/ubuntu:act-22.04` - Optimized for GitHub Actions

### Pre-installed Software
- GitHub Actions Runner (v2.325.0)
- Node.js and npm
- GitHub CLI (`gh`)
- Playwright system dependencies (browsers downloaded on-demand)
- Common build tools

### User Configuration
- Username: `ciuser` (UID: 10001, GID: 10001)
- Working directory: `/runner`
- Home directory: `/home/ciuser`
- Sudo: Passwordless enabled

## Persistent Storage (Optional)

By default, containers are ephemeral - all cache and build artifacts are lost when the container stops. For persistent storage:

### Docker Run
```bash
docker run -d \
  -v runner-work:/workspace \
  -e RUNNER_URL="..." \
  -e RUNNER_TOKEN="..." \
  -e RUNNER_NAME="..." \
  ghcr.io/handyshed/github-actions-runner:latest
```

### Docker Compose
Uncomment the volume sections in `docker-compose.yml`:
```yaml
services:
  runner-1:
    # ... other config ...
    volumes:
      - runner1-work:/workspace

volumes:
  runner1-work:
```

## Using in GitHub Actions Workflows

Reference your containerized runners using labels:

```yaml
jobs:
  test:
    runs-on: [self-hosted, containerized, Linux]
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run Playwright tests
        run: npx playwright test
```

## Advanced Configuration

### Custom Runner Version

Build with a different runner version:
```bash
docker build --build-arg RUNNER_VERSION=2.324.0 -t custom-runner .
```

### Custom User UID/GID

If you need different UID/GID:
```bash
docker build \
  --build-arg USER_UID=20001 \
  --build-arg USER_GID=20001 \
  -t custom-runner .
```

### Resource Limits

Limit container resources:
```bash
docker run -d \
  --cpus="2.0" \
  --memory="4g" \
  -e RUNNER_URL="..." \
  -e RUNNER_TOKEN="..." \
  -e RUNNER_NAME="..." \
  ghcr.io/handyshed/github-actions-runner:latest
```

## Monitoring and Management

### View Runner Logs
```bash
docker logs -f github-runner
```

### Check Runner Status
```bash
docker exec github-runner ./Runner.Listener status
```

### Graceful Shutdown
The container handles SIGTERM/SIGINT signals and will:
1. Stop accepting new jobs
2. Complete any running job
3. Deregister from GitHub
4. Exit cleanly

```bash
docker stop github-runner
```

## Security Considerations

1. **Token Security**: Registration tokens are sensitive. Use secrets management:
   - Docker secrets
   - Environment variable encryption
   - Short-lived tokens

2. **Network Isolation**: Consider using custom Docker networks:
   ```bash
   docker network create runners
   docker run --network runners ...
   ```

3. **Read-only Filesystem**: For additional security:
   ```bash
   docker run --read-only \
     --tmpfs /tmp \
     --tmpfs /runner/_work \
     ...
   ```

## Troubleshooting

### Runner Not Appearing in GitHub
- Verify the registration token is valid (they expire after 1 hour)
- Check container logs: `docker logs github-runner`
- Ensure RUNNER_URL is correct format
- Verify network connectivity to GitHub

### Permission Errors
- The container runs as `ciuser` (UID 10001)
- Ensure volume permissions match if using persistent storage
- Use `--user 10001:10001` if needed

### Playwright Tests Failing
- Browser binaries are downloaded on first use
- System dependencies are pre-installed
- Check available disk space for browser downloads

### Container Exits Immediately
- Check environment variables are set correctly
- Verify registration token is valid
- Review logs for specific error messages

## Building the Image

### Local Build
```bash
docker build -t ghcr.io/handyshed/github-actions-runner:latest .
```

### Multi-architecture Build
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/handyshed/github-actions-runner:latest \
  --push .
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.