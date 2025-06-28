# GitHub Actions Custom Runner Image

## Purpose

This repository maintains a custom Docker image for GitHub Actions self-hosted runners that provides:
- Pre-installed Playwright system dependencies to speed up CI/CD workflows
- A non-root user with UID 10001 that matches the host runner user
- Passwordless sudo access for installation flexibility
- A minimal, optimized base image for faster pulls and builds

## Technical Decisions

### Base Image: ghcr.io/catthehacker/ubuntu:act-22.04

We chose this base image because:
- It's specifically optimized for GitHub Actions compatibility
- Maintained by the nektos/act community (for running Actions locally)
- Smaller than official GitHub runner images (~500MB vs ~20GB)
- Includes essential tools while remaining minimal
- Regular security updates and active maintenance

### UID Choice: 10001

The UID 10001 was selected because:
- **High enough** to avoid conflicts with system users (0-999)
- **Avoids conflicts** with regular user UIDs (typically start at 1000)
- **Easy to remember** and document across teams
- **Predictable** - reduces configuration complexity
- **Must be synchronized** with host runner user via Infrastructure as Code

### User Configuration

- Username: `ciuser` (CI User)
- UID/GID: 10001
- Home: `/home/ciuser`
- Working Directory: `/workspace`
- Sudo: NOPASSWD enabled for flexibility during builds

### Pre-installed Dependencies

Playwright system dependencies are installed during the image build because:
- Saves approximately 2-3 minutes per workflow run
- These dependencies rarely change between runs
- Trade-off: Larger image size (~200MB extra) for significantly faster CI/CD
- Includes dependencies for Chromium, Firefox, and WebKit

## External Interface Requirements

### Critical Host Requirement

**The host MUST have a user with UID 10001**. This is non-negotiable because:
- Files created in the container will be owned by UID 10001
- The host runner needs to clean up these files between runs
- Mismatched UIDs cause "Permission denied" errors
- GitHub Actions expects the runner to own all workspace files

### Implementation in Infrastructure as Code

```hcl
# Terraform example
resource "aws_instance" "runner" {
  user_data = <<-EOF
    #!/bin/bash
    useradd -u 10001 -m -s /bin/bash runner
    # ... rest of runner setup
  EOF
}
```

```typescript
// Pulumi example
const userData = `#!/bin/bash
useradd -u 10001 -m -s /bin/bash runner
# ... rest of runner setup
`;
```

## Common Issues and Solutions

### 1. Permission Denied Errors

**Symptom**: Cannot write files or cleanup workspace
**Cause**: Host user UID doesn't match container user UID
**Solution**: Verify with `id runner` on host, ensure UID is 10001

### 2. Playwright Browser Download

**Symptom**: Playwright tries to download browsers on every run
**Cause**: Browser binaries aren't included (only system deps)
**Solution**: Cache `~/.cache/ms-playwright` in your workflow or pre-install in a derived image

### 3. Slow Initial Pull

**Symptom**: First workflow run takes long time
**Cause**: Image is ~700MB due to pre-installed dependencies
**Solution**: Ensure runners have good network connectivity or pre-pull the image

### 4. Different UID Requirements

**Symptom**: Organization uses different UID standard
**Solution**: Build custom image with `--build-arg USER_UID=<your-uid>`

## Future Enhancements

### Short Term
- [ ] Add image vulnerability scanning in CI pipeline
- [ ] Create multi-architecture builds (arm64 support)
- [ ] Add common CLI tools (jq, yq, etc.)
- [ ] Implement layer caching in build workflow

### Medium Term
- [ ] Create variant images with different pre-installed tools
- [ ] Add Python and other runtime environments
- [ ] Implement automated dependency updates
- [ ] Add health check endpoint

### Long Term
- [ ] Create slim variant without Playwright deps
- [ ] Support for different base OS versions
- [ ] Integration with runner controller
- [ ] Automated performance benchmarking

## Maintenance Notes

### Updating Playwright Dependencies

When Playwright releases new versions:
1. Rebuild the image to get latest system dependencies
2. Test with a sample Playwright project
3. Tag with both `latest` and version-specific tags

### Security Updates

- Base image updates: Monthly rebuilds recommended
- CVE monitoring: Set up GitHub Dependabot
- Regular audits: Use `docker scan` before pushing

### Version Strategy

- `latest`: Always points to the most recent build
- `vYYYY.MM.DD`: Date-based tags for stability
- `sha-XXXXXXX`: Git SHA tags for precise reproduction

## Development Workflow

1. Make changes to Dockerfile
2. Build locally: `docker build -t test-runner .`
3. Test with a sample workflow
4. Push changes to feature branch
5. CI automatically builds and validates
6. Merge to main triggers push to GHCR

## Related Resources

- [Base Image Repository](https://github.com/catthehacker/docker_images)
- [GitHub Actions Runner Documentation](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Playwright System Requirements](https://playwright.dev/docs/intro#system-requirements)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)