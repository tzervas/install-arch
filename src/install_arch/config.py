"""Configuration management for install-arch project."""

import os
import tomllib
from pathlib import Path
from typing import Any, Dict, List, Optional, Union


class Config:
    """Main configuration manager for install-arch."""

    def __init__(self, config_path: Optional[Path] = None, local_config_path: Optional[Path] = None):
        # Default config paths
        if config_path is None:
            config_path = Path(__file__).parent.parent.parent / "config.toml"

        if local_config_path is None:
            local_config_path = Path(__file__).parent.parent.parent / "local-config.toml"

        self.config_path = config_path
        self.local_config_path = local_config_path
        self._config: Dict[str, Any] = {}
        self._local_config: Dict[str, Any] = {}

        # Load main config
        if config_path.exists():
            with open(config_path, "rb") as f:
                self._config = tomllib.load(f)

        # Load local config (overrides main config)
        if local_config_path.exists():
            with open(local_config_path, "rb") as f:
                self._local_config = tomllib.load(f)

    def _get_value(self, key_path: str, default: Any = None) -> Any:
        """Get a configuration value with environment variable override support."""
        keys = key_path.split(".")

        # Check environment variable first (format: INSTALL_ARCH_{SECTION}_{KEY})
        env_key = f"INSTALL_ARCH_{'_'.join(k.upper() for k in keys)}"
        env_value = os.getenv(env_key)
        if env_value is not None:
            # Try to convert string values to appropriate types
            if env_value.lower() in ("true", "false"):
                return env_value.lower() == "true"
            try:
                return int(env_value)
            except ValueError:
                try:
                    return float(env_value)
                except ValueError:
                    return env_value

        # Check local config
        value = self._get_nested_value(self._local_config, keys)
        if value is not None:
            return value

        # Check main config
        value = self._get_nested_value(self._config, keys)
        if value is not None:
            return value

        return default

    def _get_nested_value(self, config: Dict[str, Any], keys: List[str]) -> Any:
        """Get a nested value from config dictionary."""
        current = config
        for key in keys:
            if isinstance(current, dict) and key in current:
                current = current[key]
            else:
                return None
        return current

    # Application properties
    @property
    def app_name(self) -> str:
        return self._get_value("application.name", "install-arch")

    @property
    def app_version(self) -> str:
        return self._get_value("application.version", "1.1.1")

    @property
    def app_description(self) -> str:
        return self._get_value("application.description", "")

    # URL properties
    @property
    def uv_install_url(self) -> str:
        return self._get_value("urls.uv_install_url", "https://astral.sh/uv/install.sh")

    @property
    def poetry_install_url(self) -> str:
        return self._get_value("urls.poetry_install_url", "https://install.python-poetry.org")

    @property
    def arch_mirrors(self) -> List[str]:
        return self._get_value("urls.arch_mirrors", [])

    @property
    def ventoy_base_url(self) -> str:
        return self._get_value("urls.ventoy_base_url", "https://github.com/ventoy/Ventoy/releases/download")

    # Version properties
    @property
    def arch_iso_version(self) -> str:
        return self._get_value("versions.arch_iso_version", "2025.12.01")

    @property
    def ventoy_version(self) -> str:
        return self._get_value("versions.ventoy_version", "1.0.99")

    @property
    def python_min_version(self) -> str:
        return self._get_value("versions.python_min_version", "3.11")

    # Path properties
    @property
    def workspace_dir(self) -> str:
        return self._get_value("paths.workspace_dir", "/workspaces/install-arch")

    @property
    def temp_base_dir(self) -> str:
        return self._get_value("paths.temp_base_dir", "/tmp/install-arch")

    @property
    def ventoy_extract_dir(self) -> str:
        version = self.ventoy_version
        return self._get_value("paths.ventoy_extract_dir", f"ventoy-{version}-linux")

    @property
    def iso_filename(self) -> str:
        version = self.arch_iso_version
        return self._get_value("paths.iso_filename", f"archlinux-{version}-x86_64.iso")

    # Network properties
    @property
    def dns_test_ip(self) -> str:
        return self._get_value("network.dns_test_ip", "8.8.8.8")

    @property
    def docker_registry_url(self) -> str:
        return self._get_value("network.docker_registry_url", "https://index.docker.io/v2/")

    # Virtualization properties
    @property
    def qemu_monitor_port(self) -> int:
        return self._get_value("virtualization.qemu_monitor_port", 4444)

    @property
    def qemu_qmp_port(self) -> int:
        return self._get_value("virtualization.qemu_qmp_port", 4445)

    @property
    def qemu_host_ip(self) -> str:
        return self._get_value("virtualization.qemu_host_ip", "127.0.0.1")

    # Security properties
    @property
    def secure_temp_enabled(self) -> bool:
        return self._get_value("security.secure_temp_enabled", True)

    @property
    def validate_checksums(self) -> bool:
        return self._get_value("security.validate_checksums", True)

    @property
    def require_encryption(self) -> bool:
        return self._get_value("security.require_encryption", True)

    # Development properties (legacy compatibility)
    @property
    def package_manager(self) -> str:
        return self._get_value("development.package_manager", "uv")

    @property
    def venv_path(self) -> str:
        return self._get_value("development.venv_path", ".venv")

    @property
    def python_version(self) -> str:
        return self._get_value("development.python_version", "3.11")

    @property
    def use_git_ops(self) -> bool:
        return self._get_value("development.use_git_ops", True)

    @property
    def use_secure_tmp(self) -> bool:
        return self.secure_temp_enabled


# Legacy DevConfig class for backward compatibility
class DevConfig(Config):
    """Legacy configuration class for backward compatibility."""

    def __init__(self, config_path: Optional[Path] = None):
        # For legacy compatibility, try dev-config.toml first, then fall back to config.toml
        dev_config_path = Path(__file__).parent.parent.parent / "dev-config.toml"
        main_config_path = Path(__file__).parent.parent.parent / "config.toml"

        if dev_config_path.exists():
            super().__init__(dev_config_path, None)
        else:
            super().__init__(main_config_path, None)
