"""Configuration management for development environment."""

import os
import tomllib
from pathlib import Path
from typing import Any, Dict


class DevConfig:
    """Development environment configuration manager."""

    def __init__(self, config_path: Path = None):
        if config_path is None:
            config_path = Path(__file__).parent.parent.parent / "dev-config.toml"

        self.config_path = config_path
        self._config: Dict[str, Any] = {}

        if config_path.exists():
            with open(config_path, "rb") as f:
                self._config = tomllib.load(f)
        else:
            # Default configuration
            self._config = {
                "package_manager": {
                    "tool": "uv",
                    "venv_path": ".venv",
                    "python_version": "3.11"
                },
                "filesystem": {
                    "use_git_ops": True,
                    "tmp_base_dir": "/tmp/install-arch-dev",
                    "use_secure_tmp": True
                }
            }

    @property
    def package_manager(self) -> str:
        """Get the configured package manager."""
        return self._config.get("package_manager", {}).get("tool", "uv")

    @property
    def venv_path(self) -> str:
        """Get the virtual environment path."""
        return self._config.get("package_manager", {}).get("venv_path", ".venv")

    @property
    def python_version(self) -> str:
        """Get the Python version."""
        return self._config.get("package_manager", {}).get("python_version", "3.11")

    @property
    def use_git_ops(self) -> bool:
        """Whether to use git for filesystem operations."""
        return self._config.get("filesystem", {}).get("use_git_ops", True)

    @property
    def tmp_base_dir(self) -> str:
        """Get the base directory for temporary files."""
        return self._config.get("filesystem", {}).get("tmp_base_dir", "/tmp/install-arch-dev")

    @property
    def use_secure_tmp(self) -> bool:
        """Whether to use secure temporary directories."""
        return self._config.get("filesystem", {}).get("use_secure_tmp", True)