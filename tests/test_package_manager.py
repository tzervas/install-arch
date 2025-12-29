"""Tests for package manager utilities."""

import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock
from install_arch.package_manager import PackageManager
from install_arch.config import DevConfig


class TestPackageManager:
    """Test cases for PackageManager."""

    def test_init_with_default_config(self):
        """Test initialization with default config."""
        pkg_mgr = PackageManager()
        assert isinstance(pkg_mgr.config, DevConfig)
        assert pkg_mgr.tool == "uv"

    def test_init_with_custom_config(self):
        """Test initialization with custom config."""
        config = DevConfig()
        pkg_mgr = PackageManager(config)
        assert pkg_mgr.config == config
        assert pkg_mgr.tool == "uv"

    @patch('install_arch.package_manager.subprocess.run')
    def test_run_command_success(self, mock_run, tmp_path):
        """Test successful command execution."""
        pkg_mgr = PackageManager()

        mock_run.return_value = MagicMock(returncode=0, stdout="success", stderr="")

        result = pkg_mgr._run_command(["echo", "test"], cwd=tmp_path)
        assert result.returncode == 0
        mock_run.assert_called_once()

    @patch('install_arch.package_manager.subprocess.run')
    def test_run_command_failure(self, mock_run, tmp_path):
        """Test failed command execution."""
        pkg_mgr = PackageManager()

        mock_run.side_effect = Exception("Command failed")

        with pytest.raises(Exception):
            pkg_mgr._run_command(["failing", "command"], cwd=tmp_path)

    @patch('install_arch.package_manager.PackageManager._run_command')
    def test_is_uv_installed_true(self, mock_run):
        """Test uv installation check when installed."""
        pkg_mgr = PackageManager()

        mock_run.return_value = MagicMock(returncode=0)

        assert pkg_mgr._is_uv_installed() is True
        mock_run.assert_called_once_with(["uv", "--version"])

    @patch('install_arch.package_manager.PackageManager._run_command')
    def test_is_uv_installed_false(self, mock_run):
        """Test uv installation check when not installed."""
        pkg_mgr = PackageManager()

        mock_run.side_effect = FileNotFoundError

        assert pkg_mgr._is_uv_installed() is False

    @patch('install_arch.package_manager.PackageManager._run_command')
    @patch('install_arch.package_manager.PackageManager._is_uv_installed')
    def test_install_tool_uv_not_installed(self, mock_is_installed, mock_run):
        """Test uv installation when not installed."""
        pkg_mgr = PackageManager()
        mock_is_installed.return_value = False

        pkg_mgr.install_tool()

        # Should install uv
        assert mock_run.call_count == 1
        args = mock_run.call_args[0][0]
        assert "bash" in args
        assert "uv" in " ".join(args)

    @patch('install_arch.package_manager.PackageManager._run_command')
    @patch('install_arch.package_manager.PackageManager._is_uv_installed')
    def test_install_tool_uv_already_installed(self, mock_is_installed, mock_run):
        """Test uv installation when already installed."""
        pkg_mgr = PackageManager()
        mock_is_installed.return_value = True

        pkg_mgr.install_tool()

        # Should not install uv
        mock_run.assert_not_called()

    @patch('install_arch.package_manager.PackageManager._run_command')
    def test_create_venv_uv(self, mock_run, tmp_path):
        """Test venv creation with uv."""
        config = DevConfig()
        pkg_mgr = PackageManager(config)

        venv_path = tmp_path / "test_venv"
        result = pkg_mgr.create_venv(venv_path)

        assert result == venv_path
        mock_run.assert_called_once_with(["uv", "venv", str(venv_path)])

    @patch('install_arch.package_manager.PackageManager._run_command')
    def test_create_venv_pip(self, mock_run, tmp_path):
        """Test venv creation with pip."""
        config = DevConfig()
        config._config['package_manager']['tool'] = 'pip'
        pkg_mgr = PackageManager(config)

        venv_path = tmp_path / "test_venv"
        result = pkg_mgr.create_venv(venv_path)

        assert result == venv_path
        mock_run.assert_called_once()
        args = mock_run.call_args[0][0]
        assert "venv" in args

    @patch('install_arch.package_manager.PackageManager._run_command')
    def test_install_dependencies_uv(self, mock_run):
        """Test dependency installation with uv."""
        config = DevConfig()
        pkg_mgr = PackageManager(config)

        pkg_mgr.install_dependencies(dev=True)

        expected_calls = [
            mock_run.call_args_list[0][0][0],  # First call
        ]
        assert "uv" in expected_calls[0]
        assert "pip" in expected_calls[0]
        assert "install" in expected_calls[0]
        assert "-e" in expected_calls[0]
        assert "--dev" in expected_calls[0]

    @patch('install_arch.package_manager.PackageManager._run_command')
    def test_install_dependencies_pip(self, mock_run, tmp_path):
        """Test dependency installation with pip."""
        config = DevConfig()
        config._config['package_manager']['tool'] = 'pip'
        pkg_mgr = PackageManager(config)

        # Mock venv path
        config._config['package_manager']['venv_path'] = str(tmp_path / "venv")
        pkg_mgr.install_dependencies(dev=False)

        mock_run.assert_called_once()
        args = mock_run.call_args[0][0]
        assert str(tmp_path / "venv" / "bin" / "pip") in args
        assert "install" in args
        assert "-e" in args

    def test_activate_venv_uv(self):
        """Test venv activation command for uv."""
        config = DevConfig()
        pkg_mgr = PackageManager(config)

        config._config['package_manager']['venv_path'] = '/test/venv'
        cmd = pkg_mgr.activate_venv()
        assert cmd == "source /test/venv/bin/activate"

    def test_activate_venv_poetry(self):
        """Test venv activation command for poetry."""
        config = DevConfig()
        config._config['package_manager']['tool'] = 'poetry'
        pkg_mgr = PackageManager(config)

        cmd = pkg_mgr.activate_venv()
        assert cmd == "poetry shell"

    def test_activate_venv_pipenv(self):
        """Test venv activation command for pipenv."""
        config = DevConfig()
        config._config['package_manager']['tool'] = 'pipenv'
        pkg_mgr = PackageManager(config)

        cmd = pkg_mgr.activate_venv()
        assert cmd == "pipenv shell"