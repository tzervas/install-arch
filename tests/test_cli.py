"""Tests for CLI interface."""

import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock
from click.testing import CliRunner
from install_arch.cli import cli
from install_arch.config import DevConfig
from install_arch.filesystem import FileSystemOps
from install_arch.package_manager import PackageManager


class TestCLI:
    """Test cases for CLI commands."""

    @pytest.fixture
    def runner(self):
        """CLI test runner."""
        return CliRunner()

    @pytest.fixture
    def mock_context(self):
        """Mock CLI context."""
        ctx = MagicMock()
        ctx.obj = {
            'config': DevConfig(),
            'fs_ops': FileSystemOps(),
            'pkg_mgr': PackageManager(),
            'validator': MagicMock()
        }
        return ctx

    def test_cli_help(self, runner):
        """Test CLI help command."""
        result = runner.invoke(cli, ['--help'])
        assert result.exit_code == 0
        assert 'Install Arch development environment manager' in result.output
        assert 'setup' in result.output
        assert 'check-guardrails' in result.output

    @patch('install_arch.cli.PackageManager')
    @patch('install_arch.cli.FileSystemOps')
    @patch('install_arch.cli.DevConfig')
    def test_setup_command(self, mock_config, mock_fs_ops, mock_pkg_mgr, runner, tmp_path):
        """Test setup command."""
        # Setup mocks
        mock_config_instance = MagicMock()
        mock_config.return_value = mock_config_instance
        mock_config_instance.package_manager = "uv"

        mock_pkg_mgr_instance = MagicMock()
        mock_pkg_mgr.return_value = mock_pkg_mgr_instance
        mock_pkg_mgr_instance.create_venv.return_value = tmp_path / "venv"
        mock_pkg_mgr_instance.activate_venv.return_value = "source venv/bin/activate"

        mock_fs_ops_instance = MagicMock()
        mock_fs_ops.return_value = mock_fs_ops_instance
        mock_fs_ops_instance.config.use_secure_tmp = True

        result = runner.invoke(cli, ['setup'])
        assert result.exit_code == 0
        assert 'Setting up development environment' in result.output
        assert 'Created virtual environment' in result.output
        assert 'Installed dependencies' in result.output

        mock_pkg_mgr_instance.install_tool.assert_called_once()
        mock_pkg_mgr_instance.create_venv.assert_called_once()
        mock_pkg_mgr_instance.install_dependencies.assert_called_once_with(dev=True)

    def test_stage_command(self, runner, mock_context, tmp_path):
        """Test stage command."""
        test_file = tmp_path / "test.txt"
        test_file.write_text("content")

        with patch('install_arch.cli.click.pass_context'):
            with patch.object(mock_context.obj['fs_ops'], 'stage_files') as mock_stage:
                # Simulate the command
                from install_arch.cli import stage
                stage([str(test_file)], mock_context)

                mock_stage.assert_called_once()
                args = mock_stage.call_args[0][0]
                assert len(args) == 1
                assert args[0] == test_file

    def test_commit_command(self, runner, mock_context):
        """Test commit command."""
        with patch('install_arch.cli.click.pass_context'):
            with patch.object(mock_context.obj['fs_ops'], 'commit_changes') as mock_commit:
                from install_arch.cli import commit
                commit("Test message", mock_context)

                mock_commit.assert_called_once_with("Test message")

    def test_temp_dir_command(self, runner, mock_context, tmp_path):
        """Test temp-dir command."""
        with patch('install_arch.cli.click.pass_context'):
            with patch.object(mock_context.obj['fs_ops'], 'create_secure_temp_dir', return_value=tmp_path / "temp") as mock_create:
                from install_arch.cli import temp_dir
                temp_dir("test-", mock_context)

                mock_create.assert_called_once_with("test-")

    def test_temp_file_command(self, runner, mock_context, tmp_path):
        """Test temp-file command."""
        with patch('install_arch.cli.click.pass_context'):
            with patch.object(mock_context.obj['fs_ops'], 'create_temp_file', return_value=tmp_path / "temp.txt") as mock_create:
                from install_arch.cli import temp_file
                temp_file(".txt", "test-", mock_context)

                mock_create.assert_called_once_with(".txt", "test-")

    def test_clean_temp_command(self, runner, mock_context):
        """Test clean-temp command."""
        with patch('install_arch.cli.click.pass_context'):
            with patch('install_arch.cli.shutil.rmtree') as mock_rmtree:
                with patch('install_arch.cli.Path') as mock_path:
                    mock_temp_base = MagicMock()
                    mock_path.return_value = mock_temp_base
                    mock_temp_base.exists.return_value = True

                    from install_arch.cli import clean_temp
                    clean_temp(mock_context)

                    mock_rmtree.assert_called_once_with(mock_temp_base, ignore_errors=True)
                    mock_temp_base.mkdir.assert_called_once()

    def test_check_guardrails_command_compliant(self, runner, mock_context):
        """Test check-guardrails command when compliant."""
        mock_validator = mock_context.obj['validator']
        mock_validator.check_compliance.return_value = {
            "package_manager_supported": True,
            "venv_properly_created": True,
            "git_operations_available": True,
            "temp_security_compliant": True,
            "devcontainer_usage": True,
        }
        mock_validator.get_violations.return_value = []

        result = runner.invoke(cli, ['check-guardrails'])
        assert result.exit_code == 0
        assert 'All guardrails compliant' in result.output

    def test_check_guardrails_command_violations(self, runner, mock_context):
        """Test check-guardrails command with violations."""
        mock_validator = mock_context.obj['validator']
        mock_validator.check_compliance.return_value = {
            "package_manager_supported": False,
            "venv_properly_created": True,
            "git_operations_available": True,
            "temp_security_compliant": True,
            "devcontainer_usage": True,
        }
        mock_validator.get_violations.return_value = ["Package manager not supported"]

        result = runner.invoke(cli, ['check-guardrails'])
        assert result.exit_code == 1
        assert 'Violations found' in result.output
        assert 'Package manager not supported' in result.output

    def test_enforce_guardrails_command_compliant(self, runner, mock_context):
        """Test enforce-guardrails command when compliant."""
        mock_validator = mock_context.obj['validator']
        mock_validator.get_violations.return_value = []

        result = runner.invoke(cli, ['enforce-guardrails'])
        assert result.exit_code == 0
        assert 'Guardrails compliance confirmed' in result.output

    def test_enforce_guardrails_command_violations(self, runner, mock_context):
        """Test enforce-guardrails command with violations."""
        mock_validator = mock_context.obj['validator']
        mock_validator.get_violations.return_value = ["Test violation"]

        result = runner.invoke(cli, ['enforce-guardrails'])
        assert result.exit_code == 1
        assert 'Guardrails enforcement failed' in result.output