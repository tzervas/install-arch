"""Command-line interface for development environment management."""

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

import click

from .config import DevConfig
from .filesystem import FileSystemOps
from .guardrails import GuardrailsValidator
from .package_manager import PackageManager


def _get_registry_username(env_var: str, registry_name: str) -> str:
    """Get username for registry from environment or git config.
    
    Attempts to resolve username in the following order:
    1. Environment variable (e.g., DOCKERHUB_USERNAME, GITHUB_USERNAME)
    2. GitHub username from git remote origin URL (assumes GitHub-based workflow)
    
    Note: The git fallback extracts the GitHub username, which is typically
    appropriate for both GitHub Container Registry and Docker Hub in GitHub-based
    projects where usernames often match.
    
    Args:
        env_var: Environment variable name to check (e.g., 'DOCKERHUB_USERNAME')
        registry_name: Human-readable registry name for error messages
    
    Returns:
        Username string
        
    Raises:
        click.ClickException: If username cannot be determined
    """
    # First check environment variable
    username = os.environ.get(env_var)
    if username:
        return username
    
    # Fallback: extract GitHub username from git remote origin URL
    # This assumes a GitHub-based workflow where the GitHub username is appropriate
    try:
        result = subprocess.run(
            ["git", "config", "--get", "remote.origin.url"],
            capture_output=True,
            text=True,
            check=True,
        )
        remote_url = result.stdout.strip()
        
        # Extract username from GitHub URL patterns:
        # https://github.com/username/repo.git
        # git@github.com:username/repo.git
        match = re.search(r'github\.com[:/]([^/]+)/', remote_url)
        if match:
            return match.group(1)
    except (subprocess.CalledProcessError, AttributeError):
        pass
    
    # If all else fails, provide helpful error message
    raise click.ClickException(
        f"Could not determine username for {registry_name}. "
        f"Please set the {env_var} environment variable.\n"
        f"Example: export {env_var}=your-username"
    )


@click.group()
@click.option(
    "--config",
    "config_path",
    type=click.Path(exists=True),
    help="Path to dev-config.toml",
)
@click.pass_context
def cli(ctx, config_path):
    """Install Arch development environment manager."""
    config = DevConfig(Path(config_path) if config_path else None)
    fs_ops = FileSystemOps(config)
    pkg_mgr = PackageManager(config)

    ctx.ensure_object(dict)
    ctx.obj["config"] = config
    ctx.obj["fs_ops"] = fs_ops
    ctx.obj["pkg_mgr"] = pkg_mgr
    ctx.obj["validator"] = GuardrailsValidator()


@cli.command()
@click.pass_context
def setup(ctx):
    """Set up the development environment."""
    config = ctx.obj["config"]
    fs_ops = ctx.obj["fs_ops"]
    pkg_mgr = ctx.obj["pkg_mgr"]

    click.echo(f"Setting up development environment with {config.package_manager}...")

    # Install package manager
    pkg_mgr.install_tool()

    # Create virtual environment
    venv_path = pkg_mgr.create_venv()
    click.echo(f"Created virtual environment at {venv_path}")

    # Install dependencies
    pkg_mgr.install_dependencies(dev=True)
    click.echo("Installed dependencies")

    # Create secure temp directory structure
    if config.use_secure_tmp:
        temp_base = fs_ops.create_secure_temp_dir("dev-setup-")
        click.echo(f"Created secure temp directory at {temp_base}")

    click.echo("Development environment setup complete!")
    click.echo(f"Activate with: {pkg_mgr.activate_venv()}")


@cli.command()
@click.argument("files", nargs=-1, type=click.Path(exists=True))
@click.pass_context
def stage(ctx, files):
    """Stage files for commit using git."""
    fs_ops = ctx.obj["fs_ops"]

    if not files:
        click.echo("No files specified")
        return

    fs_ops.stage_files([Path(f) for f in files])
    click.echo(f"Staged {len(files)} files")


@cli.command()
@click.argument("message")
@click.pass_context
def commit(ctx, message):
    """Commit staged changes."""
    fs_ops = ctx.obj["fs_ops"]

    fs_ops.commit_changes(message)
    click.echo("Changes committed")


@cli.command()
@click.option("--prefix", default="install-arch-", help="Prefix for temp directory")
@click.pass_context
def temp_dir(ctx, prefix):
    """Create a secure temporary directory."""
    fs_ops = ctx.obj["fs_ops"]

    temp_dir = fs_ops.create_secure_temp_dir(prefix)
    click.echo(f"Created temporary directory: {temp_dir}")


@cli.command()
@click.option("--suffix", default="", help="File suffix")
@click.option("--prefix", default="install-arch-", help="File prefix")
@click.pass_context
def temp_file(ctx, suffix, prefix):
    """Create a secure temporary file."""
    fs_ops = ctx.obj["fs_ops"]

    temp_file = fs_ops.create_temp_file(suffix, prefix)
    click.echo(f"Created temporary file: {temp_file}")


@cli.command()
@click.pass_context
def clean_temp(ctx):
    """Clean up temporary files and directories."""
    fs_ops = ctx.obj["fs_ops"]

    # This would need to track created temp files/dirs
    # For now, just clean the base temp directory

    temp_base = Path(fs_ops.config.tmp_base_dir)
    if temp_base.exists():
        shutil.rmtree(temp_base)
        temp_base.mkdir(parents=True)
        click.echo("Cleaned temporary files")
    else:
        click.echo("No temporary directory to clean")


@cli.command()
@click.pass_context
def check_guardrails(ctx):
    """Check compliance with package functionality baseline guardrails."""
    validator = ctx.obj.get("validator", GuardrailsValidator())

    compliance = validator.check_compliance()

    click.echo("Guardrails Compliance Check:")
    for check, passed in compliance.items():
        status = "✓" if passed else "✗"
        click.echo(f"  {status} {check.replace('_', ' ').title()}")

    violations = validator.get_violations()
    if violations:
        click.echo("\nViolations found:")
        for violation in violations:
            click.echo(f"  - {violation}")
        sys.exit(1)
    else:
        click.echo("\nAll guardrails compliant!")
        sys.exit(0)


@cli.command()
@click.pass_context
def enforce_guardrails(ctx):
    """Enforce guardrails compliance (will exit with error if violations found)."""
    validator = ctx.obj.get("validator", GuardrailsValidator())

    try:
        validator.enforce_guardrails()
        click.echo("Guardrails compliance confirmed!")
    except RuntimeError as e:
        click.echo(f"Guardrails enforcement failed:\n{e}", err=True)
        sys.exit(1)


@cli.command()
@click.pass_context
def local_ci(ctx):
    """Run local CI-equivalent checks (guardrails, tests, linting)."""

    click.echo("🚀 Running local CI checks...")
    click.echo()

    # Colors for output
    GREEN = "\033[0;32m"
    RED = "\033[0;31m"
    NC = "\033[0m"

    def run_check(name, command, cwd=None):
        """Run a check command and return success status."""
        click.echo(f"📋 {name}")
        try:
            result = subprocess.run(
                command,
                shell=True,
                cwd=cwd,
                capture_output=True,
                text=True,
                timeout=300,  # 5 minute timeout
            )
            if result.returncode == 0:
                click.echo(f"{GREEN}✅ {name} passed{NC}")
                return True
            else:
                click.echo(f"{RED}❌ {name} failed{NC}")
                click.echo("Output:", err=True)
                click.echo(result.stdout, err=True)
                click.echo(result.stderr, err=True)
                return False
        except subprocess.TimeoutExpired:
            click.echo(f"{RED}❌ {name} timed out{NC}", err=True)
            return False
        except Exception as e:
            click.echo(f"{RED}❌ {name} error: {e}{NC}", err=True)
            return False

    checks = [
        ("Guardrails Check", "uv run python -m install_arch.cli check-guardrails"),
        (
            "Tests with Coverage",
            "uv run pytest tests/ --cov=src/install_arch --cov-fail-under=80",
        ),
        ("Ruff", "uv run ruff check src/ tests/"),
        ("MyPy", "uv run mypy src/install_arch/"),
        ("Ruff Format Check", "uv run ruff format --check src/ tests/"),
    ]

    all_passed = True
    for name, command in checks:
        if not run_check(name, command):
            all_passed = False

    click.echo()
    if all_passed:
        click.echo(
            f"{GREEN}🎉 All local CI checks passed! Ready to commit and push.{NC}"
        )
        sys.exit(0)
    else:
        click.echo(
            f"{RED}❌ Some checks failed. Please fix issues before committing.{NC}",
            err=True,
        )
        sys.exit(1)


@cli.command()
@click.pass_context
def devcontainer_build(ctx):
    """Build the Dev Container image."""
    import subprocess
    import tomllib

    click.echo("Building Dev Container image...")

    # Get version from pyproject.toml
    project_root = Path(__file__).parent.parent.parent
    pyproject_path = project_root / "pyproject.toml"
    version = "latest"
    if pyproject_path.exists():
        with open(pyproject_path, "rb") as f:
            data = tomllib.load(f)
            version = data.get("project", {}).get("version", "latest")

    image_tag = f"install-arch-dev:{version}"
    click.echo(f"Building image: {image_tag}")

    try:
        result = subprocess.run(
            ["docker", "build", "-t", image_tag, ".devcontainer/"],
            cwd=project_root,
            check=True,
            capture_output=True,
            text=True,
        )
        click.echo("✅ Dev Container image built successfully")
        click.echo(f"   Image: {image_tag}")
    except subprocess.CalledProcessError as e:
        click.echo(f"❌ Failed to build Dev Container image: {e.stderr}", err=True)
        sys.exit(1)


@cli.command()
@click.option("--registry", default="all", type=click.Choice(["dockerhub", "ghcr", "all"]), help="Registry to push to")
@click.pass_context
def devcontainer_push(ctx, registry):
    """Push the Dev Container image to registries."""
    import subprocess
    import tomllib

    click.echo("Pushing Dev Container image...")

    # Get version from pyproject.toml
    project_root = Path(__file__).parent.parent.parent
    pyproject_path = project_root / "pyproject.toml"
    version = "latest"
    if pyproject_path.exists():
        with open(pyproject_path, "rb") as f:
            data = tomllib.load(f)
            version = data.get("project", {}).get("version", "latest")

    image_tag = f"install-arch-dev:{version}"

    # Get usernames dynamically from environment or git config
    registries = []
    if registry in ["dockerhub", "all"]:
        dockerhub_username = _get_registry_username("DOCKERHUB_USERNAME", "Docker Hub")
        registries.append(("docker.io", f"{dockerhub_username}/{image_tag}"))
    if registry in ["ghcr", "all"]:
        github_username = _get_registry_username("GITHUB_USERNAME", "GitHub Container Registry")
        registries.append(("ghcr.io", f"{github_username}/install-arch/{image_tag}"))

    for reg_url, full_tag in registries:
        click.echo(f"Pushing to {reg_url}...")
        try:
            # Tag for registry
            subprocess.run(["docker", "tag", image_tag, full_tag], check=True, capture_output=True)
            # Push
            subprocess.run(["docker", "push", full_tag], check=True, capture_output=True)
            click.echo(f"✅ Pushed {full_tag}")
        except subprocess.CalledProcessError as e:
            click.echo(f"❌ Failed to push to {reg_url}: {e.stderr}", err=True)
            sys.exit(1)

    click.echo("✅ All pushes completed")


@cli.command()
@click.pass_context
def devcontainer_clean(ctx):
    """Clean up Dev Container resources."""
    import subprocess

    click.echo("Cleaning up Dev Container resources...")

    project_root = Path(__file__).parent.parent.parent

    # Remove stopped containers
    try:
        result = subprocess.run(
            ["docker", "ps", "-aq", "--filter", f"label=devcontainer.local_folder={project_root}", "--filter", "status=exited"],
            capture_output=True,
            text=True,
            check=True,
        )
        if result.stdout.strip():
            containers = result.stdout.strip().split('\n')
            subprocess.run(["docker", "rm"] + containers, check=True)
            click.echo(f"✅ Removed {len(containers)} stopped containers")
        else:
            click.echo("ℹ️  No stopped containers to clean")
    except subprocess.CalledProcessError as e:
        click.echo(f"⚠️  Failed to clean containers: {e.stderr}", err=True)

    # Remove dangling images
    try:
        result = subprocess.run(
            ["docker", "images", "-f", "dangling=true", "-q"],
            capture_output=True,
            text=True,
            check=True,
        )
        if result.stdout.strip():
            images = result.stdout.strip().split('\n')
            subprocess.run(["docker", "rmi"] + images, check=True)
            click.echo(f"✅ Removed {len(images)} dangling images")
        else:
            click.echo("ℹ️  No dangling images to clean")
    except subprocess.CalledProcessError as e:
        click.echo(f"⚠️  Failed to clean images: {e.stderr}", err=True)

    # Clean volumes
    try:
        subprocess.run(["docker", "volume", "prune", "-f"], check=True, capture_output=True)
        click.echo("✅ Cleaned unused volumes")
    except subprocess.CalledProcessError as e:
        click.echo(f"⚠️  Failed to clean volumes: {e.stderr}", err=True)


@cli.command()
@click.pass_context
def devcontainer_status(ctx):
    """Show Dev Container status."""
    import os

    click.echo("Dev Container Status:")
    click.echo()

    # Check if running in Dev Container
    if os.getenv("REMOTE_CONTAINERS") or os.getenv("DEVCONTAINER"):
        click.echo("✅ Running inside Dev Container")
        click.echo(f"  Workspace: {os.getcwd()}")
        click.echo(f"  User: {os.getenv('USER', 'unknown')}")

        # Check Python
        try:
            result = subprocess.run(["python", "--version"], capture_output=True, text=True, check=True)
            click.echo(f"  Python: {result.stdout.strip()}")
        except:
            click.echo("  Python: not found")

        # Check UV
        try:
            result = subprocess.run(["uv", "--version"], capture_output=True, text=True, check=True)
            click.echo(f"  UV: {result.stdout.strip()}")
        except:
            click.echo("  UV: not found")
    else:
        click.echo("⚠️  Not running inside Dev Container")

        # Check Docker
        try:
            subprocess.run(["docker", "info"], capture_output=True, check=True)
        except:
            click.echo("❌ Docker is not running")
            return

        project_root = Path(__file__).parent.parent.parent

        # Check running container
        try:
            result = subprocess.run(
                ["docker", "ps", "-q", "--filter", f"label=devcontainer.local_folder={project_root}"],
                capture_output=True,
                text=True,
                check=True,
            )
            if result.stdout.strip():
                click.echo("✅ Dev Container is running")
                click.echo(f"  Container ID: {result.stdout.strip()}")
            else:
                click.echo("⚠️  No Dev Container currently running")
        except:
            click.echo("⚠️  Could not check running containers")

        # Check image
        try:
            result = subprocess.run(
                ["docker", "images", "install-arch-dev", "-q"],
                capture_output=True,
                text=True,
                check=True,
            )
            if result.stdout.strip():
                click.echo("✅ Dev Container image exists")
                click.echo("  Image: install-arch-dev")
            else:
                click.echo("⚠️  Dev Container image does not exist")
        except:
            click.echo("⚠️  Could not check image status")


if __name__ == "__main__":
    cli()
