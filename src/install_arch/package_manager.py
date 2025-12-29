"""Package management utilities with support for multiple tools."""

import os
import subprocess
import sys
from pathlib import Path
from typing import List, Optional

from .config import DevConfig


class PackageManager:
    """Unified interface for different Python package managers."""

    def __init__(self, config: DevConfig = None):
        self.config = config or DevConfig()
        self.tool = self.config.package_manager

    def _run_command(self, cmd: List[str], cwd: Path = None) -> subprocess.CompletedProcess:
        """Run a command and return the result."""
        try:
            return subprocess.run(
                cmd,
                cwd=cwd or Path.cwd(),
                capture_output=True,
                text=True,
                check=True
            )
        except subprocess.CalledProcessError as e:
            print(f"Command failed: {' '.join(cmd)}")
            print(f"stdout: {e.stdout}")
            print(f"stderr: {e.stderr}")
            raise

    def install_tool(self) -> None:
        """Install the configured package manager if needed."""
        if self.tool == "uv":
            if not self._is_uv_installed():
                print("Installing uv...")
                self._install_uv()
        elif self.tool == "poetry":
            if not self._is_poetry_installed():
                print("Installing poetry...")
                self._install_poetry()
        # pip and pipenv are usually pre-installed

    def _is_uv_installed(self) -> bool:
        """Check if uv is installed."""
        try:
            self._run_command(["uv", "--version"])
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False

    def _install_uv(self) -> None:
        """Install uv."""
        install_script = "curl -LsSf https://astral.sh/uv/install.sh | sh"
        self._run_command(["bash", "-c", install_script])

        # Add uv to PATH
        uv_path = Path.home() / ".cargo" / "bin"
        if str(uv_path) not in os.environ.get("PATH", ""):
            os.environ["PATH"] = f"{uv_path}:{os.environ.get('PATH', '')}"

    def _is_poetry_installed(self) -> bool:
        """Check if poetry is installed."""
        try:
            self._run_command(["poetry", "--version"])
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False

    def _install_poetry(self) -> None:
        """Install poetry."""
        install_script = "curl -sSL https://install.python-poetry.org | python3 -"
        self._run_command(["bash", "-c", install_script])

    def create_venv(self, path: Path = None) -> Path:
        """Create a virtual environment."""
        venv_path = path or Path(self.config.venv_path)

        if self.tool == "uv":
            self._run_command(["uv", "venv", str(venv_path)])
        elif self.tool == "poetry":
            # Poetry creates venv automatically
            pass
        elif self.tool == "pipenv":
            # Pipenv creates venv automatically
            pass
        else:  # pip
            self._run_command([sys.executable, "-m", "venv", str(venv_path)])

        return venv_path

    def install_dependencies(self, dev: bool = False) -> None:
        """Install project dependencies."""
        if self.tool == "uv":
            cmd = ["uv", "pip", "install", "-e", "."]
            if dev:
                cmd.extend(["--dev"])
            self._run_command(cmd)
        elif self.tool == "poetry":
            cmd = ["poetry", "install"]
            if dev:
                cmd.append("--with=dev")
            self._run_command(cmd)
        elif self.tool == "pipenv":
            cmd = ["pipenv", "install", "--dev"] if dev else ["pipenv", "install"]
            self._run_command(cmd)
        else:  # pip
            venv_path = Path(self.config.venv_path)
            pip_path = venv_path / "bin" / "pip"
            cmd = [str(pip_path), "install", "-e", "."]
            if dev:
                # Install dev dependencies from pyproject.toml
                pass  # Would need to parse pyproject.toml
            self._run_command(cmd)

    def activate_venv(self) -> str:
        """Get the command to activate the virtual environment."""
        venv_path = Path(self.config.venv_path)
        if self.tool in ["uv", "pip"]:
            return f"source {venv_path}/bin/activate"
        elif self.tool == "poetry":
            return "poetry shell"
        elif self.tool == "pipenv":
            return "pipenv shell"
        return ""