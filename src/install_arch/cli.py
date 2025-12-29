"""Command-line interface for development environment management."""

import click
from pathlib import Path

from .config import DevConfig
from .filesystem import FileSystemOps
from .package_manager import PackageManager
from .guardrails import GuardrailsValidator


@click.group()
@click.option('--config', 'config_path', type=click.Path(exists=True),
              help='Path to dev-config.toml')
@click.pass_context
def cli(ctx, config_path):
    """Install Arch development environment manager."""
    config = DevConfig(Path(config_path) if config_path else None)
    fs_ops = FileSystemOps(config)
    pkg_mgr = PackageManager(config)

    ctx.ensure_object(dict)
    ctx.obj['config'] = config
    ctx.obj['fs_ops'] = fs_ops
    ctx.obj['pkg_mgr'] = pkg_mgr
    ctx.obj['validator'] = GuardrailsValidator()


@cli.command()
@click.pass_context
def setup(ctx):
    """Set up the development environment."""
    config = ctx.obj['config']
    fs_ops = ctx.obj['fs_ops']
    pkg_mgr = ctx.obj['pkg_mgr']

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
@click.argument('files', nargs=-1, type=click.Path(exists=True))
@click.pass_context
def stage(ctx, files):
    """Stage files for commit using git."""
    fs_ops = ctx.obj['fs_ops']

    if not files:
        click.echo("No files specified")
        return

    fs_ops.stage_files([Path(f) for f in files])
    click.echo(f"Staged {len(files)} files")


@cli.command()
@click.argument('message')
@click.pass_context
def commit(ctx, message):
    """Commit staged changes."""
    fs_ops = ctx.obj['fs_ops']

    fs_ops.commit_changes(message)
    click.echo("Changes committed")


@cli.command()
@click.option('--prefix', default='install-arch-', help='Prefix for temp directory')
@click.pass_context
def temp_dir(ctx, prefix):
    """Create a secure temporary directory."""
    fs_ops = ctx.obj['fs_ops']

    temp_dir = fs_ops.create_secure_temp_dir(prefix)
    click.echo(f"Created temporary directory: {temp_dir}")


@cli.command()
@click.option('--suffix', default='', help='File suffix')
@click.option('--prefix', default='install-arch-', help='File prefix')
@click.pass_context
def temp_file(ctx, suffix, prefix):
    """Create a secure temporary file."""
    fs_ops = ctx.obj['fs_ops']

    temp_file = fs_ops.create_temp_file(suffix, prefix)
    click.echo(f"Created temporary file: {temp_file}")


@cli.command()
@click.pass_context
def clean_temp(ctx):
    """Clean up temporary files and directories."""
    fs_ops = ctx.obj['fs_ops']

    # This would need to track created temp files/dirs
    # For now, just clean the base temp directory
    import shutil
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
    validator = ctx.obj['validator']

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
        return 1
    else:
        click.echo("\nAll guardrails compliant!")
        return 0


@cli.command()
@click.pass_context
def enforce_guardrails(ctx):
    """Enforce guardrails compliance (will exit with error if violations found)."""
    validator = ctx.obj['validator']

    try:
        validator.enforce_guardrails()
        click.echo("Guardrails compliance confirmed!")
    except RuntimeError as e:
        click.echo(f"Guardrails enforcement failed:\n{e}", err=True)
        sys.exit(1)


if __name__ == '__main__':
    cli()