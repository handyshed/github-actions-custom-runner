# GitHub Actions Custom Runner Image

Custom Docker image for GitHub Actions self-hosted runners with pre-installed Playwright dependencies.

## 🚨 IMPORTANT: Host Requirements

**The host system MUST have a user with UID 10001** to avoid file permission issues between the container and host.

### Host Setup

Before using this image, ensure your runner host has a user with UID 10001:

```bash
# Create a new user on the host with specific UID
sudo useradd -u 10001 -m runner

# Or modify an existing user's UID
sudo usermod -u 10001 existing-runner-user
```

### Infrastructure as Code

If you're using Pulumi, Terraform, or other IaC tools, ensure the runner user is created with UID 10001:

```typescript
// Example for Pulumi
const runnerUser = new aws.iam.User("runner", {
    // ... other config
});

// In your EC2 user data or container configuration:
// useradd -u 10001 -m runner
```

## Image Features

- **Base Image**: `ghcr.io/catthehacker/ubuntu:act-22.04` - Optimized for GitHub Actions compatibility
- **User**: `ciuser` (UID: 10001, GID: 10001)
- **Sudo**: Passwordless sudo enabled for flexibility
- **Pre-installed**: Playwright system dependencies (saves ~2-3 minutes per workflow)
- **Working Directory**: `/workspace`
- **Home Directory**: `/home/ciuser`

## Usage

### In GitHub Actions Workflows

```yaml
jobs:
  test:
    runs-on: self-hosted
    container:
      image: ghcr.io/handyshed/github-actions-runner:latest
      options: --user 10001
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Playwright tests
        run: |
          npm ci
          npx playwright test
```

### Running Locally

```bash
# Pull the image
docker pull ghcr.io/handyshed/github-actions-runner:latest

# Run with matching UID
docker run -it --rm \
  --user 10001 \
  -v $(pwd):/workspace \
  ghcr.io/handyshed/github-actions-runner:latest \
  bash
```

## Why UID 10001?

1. **High enough** to avoid conflicts with system users (0-999)
2. **Avoids conflicts** with regular users (typically start at 1000)
3. **Easy to remember** and document
4. **Consistent** across all runner hosts when properly configured

## Building the Image

### Build Locally

```bash
docker build -t ghcr.io/handyshed/github-actions-runner:latest .
```

### Build with Custom UID

If you need a different UID for your environment:

```bash
docker build --build-arg USER_UID=20001 --build-arg USER_GID=20001 -t custom-runner .
```

⚠️ **Remember**: If you change the UID, you must update your host user accordingly!

## Pre-installed Dependencies

This image includes system dependencies for:
- Playwright (Chromium, Firefox, WebKit)
- Common build tools
- Node.js and npm

## Troubleshooting

### Permission Denied Errors

If you see permission errors when writing files:
1. Verify the host user UID: `id runner`
2. Ensure it matches 10001
3. Check container is running with `--user 10001`

### Playwright Tests Failing

If Playwright tests fail:
1. Check if you need to install browsers: `npx playwright install`
2. The system dependencies are pre-installed, but browser binaries are not

### Files Created with Wrong Ownership

If files are created with the wrong owner:
1. Ensure the container is running with the correct user
2. Verify the host user UID matches the container user UID

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.