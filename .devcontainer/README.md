# Dev Container Configuration

This directory contains the configuration for the development container used in this project.

## Files

- `devcontainer.json`: Main devcontainer configuration
- `Dockerfile`: Container build instructions
- `post-create.sh`: Setup script run after container creation
- `load-env.sh`: Environment variable loader script
- `.env`: Environment variables (not committed to git)
- `.env.example`: Template for environment configuration

## Configuration

The devcontainer is parameterized using environment variables to avoid hardcoding sensitive information.

### Setup

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your specific values:
   - `DEVCONTAINER_REPO_URL`: Your repository URL
   - `DEVCONTAINER_BRANCH`: Branch to use
   - Other parameters as needed

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DEVCONTAINER_MODE` | Repository handling mode | `mount` |
| `DEVCONTAINER_BRANCH` | Git branch | `main` |
| `DEVCONTAINER_DEPTH` | Clone depth | `full` |
| `DEVCONTAINER_VERSION` | Package version | `latest` |
| `DEVCONTAINER_REPO_URL` | Repository URL | GitHub URL |

### Security

- The `.env` file is excluded from git tracking
- Never commit sensitive information like API keys or tokens
- Use the `.env` file for any sensitive configuration

## Usage

Open the project in VS Code and use "Dev Containers: Reopen in Container" to start the development environment.

The container will automatically load environment variables from `.env` and use them for configuration.