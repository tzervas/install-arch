"""Tests for configuration management."""

import pytest
from pathlib import Path
from unittest.mock import patch
from install_arch.config import DevConfig


class TestDevConfig:
    """Test cases for DevConfig."""

    def test_init_with_default_path(self):
        """Test initialization with default config path."""
        config = DevConfig()
        expected_path = Path(__file__).parent.parent / "src" / "install_arch" / "dev-config.toml"
        # Since dev-config.toml exists in project root, it should use that
        expected_path = Path(__file__).parent.parent / "dev-config.toml"
        assert config.config_path == expected_path

    def test_init_with_custom_path(self):
        """Test initialization with custom config path."""
        custom_path = Path("/custom/path.toml")
        config = DevConfig(custom_path)
        assert config.config_path == custom_path

    def test_load_existing_config(self, tmp_path):
        """Test loading an existing config file."""
        config_file = tmp_path / "test-config.toml"
        config_content = """
[package_manager]
tool = "pip"
venv_path = ".test_venv"
python_version = "3.10"

[filesystem]
use_git_ops = false
tmp_base_dir = "/tmp/test"
use_secure_tmp = false
"""
        config_file.write_text(config_content)

        config = DevConfig(config_file)
        assert config.package_manager == "pip"
        assert config.venv_path == ".test_venv"
        assert config.python_version == "3.10"
        assert config.use_git_ops is False
        assert config.tmp_base_dir == "/tmp/test"
        assert config.use_secure_tmp is False

    def test_default_config_when_no_file(self, tmp_path):
        """Test default configuration when config file doesn't exist."""
        non_existent_path = tmp_path / "nonexistent.toml"
        config = DevConfig(non_existent_path)

        # Should use defaults
        assert config.package_manager == "uv"
        assert config.venv_path == ".venv"
        assert config.python_version == "3.11"
        assert config.use_git_ops is True
        assert config.tmp_base_dir == "/tmp/install-arch-dev"
        assert config.use_secure_tmp is True

    def test_properties_with_existing_config(self):
        """Test property access with the actual config file."""
        config = DevConfig()

        # Based on dev-config.toml
        assert config.package_manager == "uv"
        assert config.venv_path == ".venv"
        assert config.python_version == "3.11"
        assert config.use_git_ops is True
        assert config.tmp_base_dir == "/tmp/install-arch-dev"
        assert config.use_secure_tmp is True