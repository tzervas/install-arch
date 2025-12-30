"""Tests for CLI interface."""

from unittest.mock import MagicMock, patch

import pytest
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
            "config": DevConfig(),
            "fs_ops": FileSystemOps(),
            "pkg_mgr": PackageManager(),
            "validator": MagicMock(),
        }
        return ctx

    def test_cli_help(self, runner):
        """Test CLI help command."""
        result = runner.invoke(cli, ["--help"])
        assert result.exit_code == 0
        assert "Install Arch development environment manager" in result.output
        assert "setup" in result.output
        assert "check-guardrails" in result.output

    @patch("install_arch.cli.PackageManager")
    @patch("install_arch.cli.FileSystemOps")
    @patch("install_arch.cli.DevConfig")
    def test_setup_command(
        self, mock_config, mock_fs_ops, mock_pkg_mgr, runner, tmp_path
    ):
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

        result = runner.invoke(cli, ["setup"])
        assert result.exit_code == 0
        assert "Setting up development environment" in result.output
        assert "Created virtual environment" in result.output
        assert "Installed dependencies" in result.output

        mock_pkg_mgr_instance.install_tool.assert_called_once()
        mock_pkg_mgr_instance.create_venv.assert_called_once()
        mock_pkg_mgr_instance.install_dependencies.assert_called_once_with(dev=True)

    def test_stage_command(self, runner, tmp_path):
        """Test stage command."""
        test_file = tmp_path / "test.txt"
        test_file.write_text("content")

        with patch("install_arch.cli.FileSystemOps") as mock_fs_class:
            mock_fs_instance = MagicMock()
            mock_fs_class.return_value = mock_fs_instance

            with patch("install_arch.cli.PackageManager") as mock_pkg_class:
                mock_pkg_instance = MagicMock()
                mock_pkg_class.return_value = mock_pkg_instance

                with patch("install_arch.cli.DevConfig") as mock_config_class:
                    mock_config_instance = MagicMock()
                    mock_config_class.return_value = mock_config_instance

                    result = runner.invoke(cli, ["stage", str(test_file)])
                    assert result.exit_code == 0
                    mock_fs_instance.stage_files.assert_called_once()

    def test_stage_command_no_files(self, runner):
        """Test stage command with no files."""
        result = runner.invoke(cli, ["stage"])
        assert result.exit_code == 0
        assert "No files specified" in result.output

    def test_commit_command(self, runner):
        """Test commit command."""
        with patch("install_arch.cli.FileSystemOps") as mock_fs_class:
            mock_fs_instance = MagicMock()
            mock_fs_class.return_value = mock_fs_instance

            with patch("install_arch.cli.PackageManager") as mock_pkg_class:
                mock_pkg_instance = MagicMock()
                mock_pkg_class.return_value = mock_pkg_instance

                with patch("install_arch.cli.DevConfig") as mock_config_class:
                    mock_config_instance = MagicMock()
                    mock_config_class.return_value = mock_config_instance

                    result = runner.invoke(cli, ["commit", "Test message"])
                    assert result.exit_code == 0
                    mock_fs_instance.commit_changes.assert_called_once_with(
                        "Test message"
                    )

    def test_temp_dir_command(self, runner, tmp_path):
        """Test temp-dir command."""
        with patch("install_arch.cli.FileSystemOps") as mock_fs_class:
            mock_fs_instance = MagicMock()
            mock_fs_instance.create_secure_temp_dir.return_value = tmp_path / "temp"
            mock_fs_class.return_value = mock_fs_instance

            with patch("install_arch.cli.PackageManager") as mock_pkg_class:
                mock_pkg_instance = MagicMock()
                mock_pkg_class.return_value = mock_pkg_instance

                with patch("install_arch.cli.DevConfig") as mock_config_class:
                    mock_config_instance = MagicMock()
                    mock_config_class.return_value = mock_config_instance

                    result = runner.invoke(cli, ["temp-dir", "--prefix", "test-"])
                    assert result.exit_code == 0
                    mock_fs_instance.create_secure_temp_dir.assert_called_once_with(
                        "test-"
                    )

    def test_temp_file_command(self, runner, tmp_path):
        """Test temp-file command."""
        with patch("install_arch.cli.FileSystemOps") as mock_fs_class:
            mock_fs_instance = MagicMock()
            mock_fs_instance.create_temp_file.return_value = tmp_path / "temp.txt"
            mock_fs_class.return_value = mock_fs_instance

            with patch("install_arch.cli.PackageManager") as mock_pkg_class:
                mock_pkg_instance = MagicMock()
                mock_pkg_class.return_value = mock_pkg_instance

                with patch("install_arch.cli.DevConfig") as mock_config_class:
                    mock_config_instance = MagicMock()
                    mock_config_class.return_value = mock_config_instance

                    result = runner.invoke(
                        cli, ["temp-file", "--suffix", ".txt", "--prefix", "test-"]
                    )
                    assert result.exit_code == 0
                    mock_fs_instance.create_temp_file.assert_called_once_with(
                        ".txt", "test-"
                    )

    @patch("install_arch.cli.shutil")
    @patch("install_arch.cli.FileSystemOps")
    @patch("install_arch.cli.DevConfig")
    def test_clean_temp_command(self, mock_config, mock_fs_ops, mock_shutil, runner):
        """Test clean-temp command."""
        # Setup mocks
        mock_config_instance = MagicMock()
        mock_config.return_value = mock_config_instance
        mock_config_instance.tmp_base_dir = "/tmp/test-clean-temp"

        mock_fs_ops_instance = MagicMock()
        mock_fs_ops.return_value = mock_fs_ops_instance
        mock_fs_ops_instance.config = mock_config_instance

        # Mock Path to return a mock with exists=True
        with patch("install_arch.cli.Path") as mock_path_class:
            mock_temp_base = MagicMock()
            mock_path_class.return_value = mock_temp_base
            mock_temp_base.exists.return_value = True

            result = runner.invoke(cli, ["clean-temp"])
            assert result.exit_code == 0
            assert "Cleaned temporary files" in result.output

    @patch("install_arch.cli.FileSystemOps")
    @patch("install_arch.cli.DevConfig")
    def test_clean_temp_command_no_dir(self, mock_config, mock_fs_ops, runner):
        """Test clean-temp command when no temp directory exists."""
        # Setup mocks
        mock_config_instance = MagicMock()
        mock_config.return_value = mock_config_instance
        mock_config_instance.tmp_base_dir = "/tmp/test-clean-temp-no-dir"

        mock_fs_ops_instance = MagicMock()
        mock_fs_ops.return_value = mock_fs_ops_instance
        mock_fs_ops_instance.config = mock_config_instance

        # Mock the Path operations
        with patch("install_arch.cli.Path") as mock_path:
            mock_temp_base = MagicMock()
            mock_path.return_value = mock_temp_base
            mock_temp_base.exists.return_value = False

            result = runner.invoke(cli, ["clean-temp"])
            assert result.exit_code == 0
            assert "No temporary directory to clean" in result.output

    def test_check_guardrails_command_compliant(self, runner):
        """Test check-guardrails command when compliant."""
        with patch("install_arch.cli.GuardrailsValidator") as mock_validator_class:
            mock_validator_instance = MagicMock()
            mock_validator_instance.check_compliance.return_value = {
                "package_manager_supported": True,
                "venv_properly_created": True,
                "git_operations_available": True,
                "temp_security_compliant": True,
                "devcontainer_usage": True,
            }
            mock_validator_instance.get_violations.return_value = []
            mock_validator_class.return_value = mock_validator_instance

            result = runner.invoke(cli, ["check-guardrails"])
            assert result.exit_code == 0
            assert "All guardrails compliant" in result.output

    @patch.dict("os.environ", {}, clear=True)
    def test_check_guardrails_command_violations(self, runner):
        """Test check-guardrails command with violations."""
        result = runner.invoke(cli, ["check-guardrails"])
        # In real environment, devcontainer is not used, so violations exist
        assert result.exit_code == 1
        assert "Violations found" in result.output

    def test_enforce_guardrails_command_compliant(self, runner):
        """Test enforce-guardrails command when compliant."""
        with patch("install_arch.cli.GuardrailsValidator") as mock_validator_class:
            mock_validator_instance = MagicMock()
            mock_validator_instance.get_violations.return_value = []
            mock_validator_class.return_value = mock_validator_instance

            with patch("install_arch.cli.FileSystemOps") as mock_fs_class:
                mock_fs_instance = MagicMock()
                mock_fs_class.return_value = mock_fs_instance

                with patch("install_arch.cli.PackageManager") as mock_pkg_class:
                    mock_pkg_instance = MagicMock()
                    mock_pkg_class.return_value = mock_pkg_instance

                    with patch("install_arch.cli.DevConfig") as mock_config_class:
                        mock_config_instance = MagicMock()
                        mock_config_class.return_value = mock_config_instance

                        result = runner.invoke(cli, ["enforce-guardrails"])
                        assert result.exit_code == 0
                        assert "Guardrails compliance confirmed" in result.output

    @patch.dict("os.environ", {}, clear=True)
    def test_enforce_guardrails_command_violations(self, runner):
        """Test enforce-guardrails command with violations."""
        result = runner.invoke(cli, ["enforce-guardrails"])
        # In real environment, devcontainer is not used, so violations exist
        assert result.exit_code == 1
        assert "Guardrails enforcement failed" in result.output

    def test_local_ci_command_exists(self, runner):
        """Test that local-ci command exists and shows help."""
        result = runner.invoke(cli, ["local-ci", "--help"])
        assert result.exit_code == 0
        assert "Run local CI-equivalent checks" in result.output

    @patch("install_arch.cli.subprocess.run")
    def test_local_ci_command_success(self, mock_subprocess_run, runner):
        """Test local-ci command when all checks pass."""
        # Mock subprocess.run to return success for all checks
        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_result.stdout = ""
        mock_result.stderr = ""
        mock_subprocess_run.return_value = mock_result

        result = runner.invoke(cli, ["local-ci"])
        assert result.exit_code == 0
        assert "All local CI checks passed" in result.output
