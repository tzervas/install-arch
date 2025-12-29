"""Tests for guardrails validation."""

import subprocess
import pytest
from pathlib import Path
from unittest.mock import patch, MagicMock
from install_arch.guardrails import GuardrailsValidator


class TestGuardrailsValidator:
    """Test cases for GuardrailsValidator."""

    def test_init_with_default_path(self):
        """Test initialization with default guardrails path."""
        validator = GuardrailsValidator()
        expected_path = (
            Path(__file__).parent.parent
            / ".github"
            / "guardrails"
            / "package-baseline.toml"
        )
        assert validator.guardrails_path == expected_path

    def test_init_with_custom_path(self):
        """Test initialization with custom guardrails path."""
        custom_path = Path("/custom/path.toml")
        validator = GuardrailsValidator(custom_path)
        assert validator.guardrails_path == custom_path

    def test_validate_package_manager_supported(self):
        """Test package manager validation when supported."""
        validator = GuardrailsValidator()
        validator._config = {"tool_configuration": {"uv": {}, "pip": {}}}
        assert validator.validate_package_manager("uv") is True
        assert validator.validate_package_manager("pip") is True
        assert validator.validate_package_manager("unknown") is False

    def test_validate_venv_creation_uv(self):
        """Test venv validation for uv."""
        validator = GuardrailsValidator()
        venv_path = Path("/tmp/test_venv")
        venv_path.mkdir(parents=True, exist_ok=True)
        (venv_path / "pyvenv.cfg").touch()

        assert validator.validate_venv_creation("uv", venv_path) is True

        # Cleanup
        (venv_path / "pyvenv.cfg").unlink()
        venv_path.rmdir()

    def test_validate_venv_creation_pip(self):
        """Test venv validation for pip."""
        validator = GuardrailsValidator()
        venv_path = Path("/tmp/test_venv")
        venv_path.mkdir(parents=True, exist_ok=True)
        (venv_path / "bin").mkdir(exist_ok=True)
        (venv_path / "bin" / "activate").touch()

        assert validator.validate_venv_creation("pip", venv_path) is True

        # Cleanup
        (venv_path / "bin" / "activate").unlink()
        (venv_path / "bin").rmdir()
        venv_path.rmdir()

    @patch("subprocess.run")
    def test_validate_git_operations_success(self, mock_run):
        """Test git operations validation when successful."""
        mock_run.return_value = MagicMock(returncode=0)
        validator = GuardrailsValidator()
        assert validator.validate_git_operations() is True

    @patch("subprocess.run")
    def test_validate_git_operations_failure(self, mock_run):
        """Test git operations validation when failed."""
        mock_run.side_effect = subprocess.CalledProcessError(1, "git")
        validator = GuardrailsValidator()
        assert validator.validate_git_operations() is False

    def test_validate_temp_security_good(self):
        """Test temp directory security validation when good."""
        validator = GuardrailsValidator()
        temp_dir = Path("/tmp/test_temp")
        temp_dir.mkdir(parents=True, exist_ok=True)
        temp_dir.chmod(0o700)

        assert validator.validate_temp_security(temp_dir) is True

        # Cleanup
        temp_dir.rmdir()

    def test_validate_temp_security_bad(self):
        """Test temp directory security validation when bad."""
        validator = GuardrailsValidator()
        temp_dir = Path("/tmp/test_temp")
        temp_dir.mkdir(parents=True, exist_ok=True)
        temp_dir.chmod(0o755)

        assert validator.validate_temp_security(temp_dir) is False

        # Cleanup
        temp_dir.rmdir()

    @patch.dict("os.environ", {"DEVCONTAINER": "1"})
    def test_validate_devcontainer_usage_true(self):
        """Test devcontainer validation when in devcontainer."""
        validator = GuardrailsValidator()
        assert validator.validate_devcontainer_usage() is True

    @patch.dict("os.environ", {}, clear=True)
    def test_validate_devcontainer_usage_false(self):
        """Test devcontainer validation when not in devcontainer."""
        validator = GuardrailsValidator()
        assert validator.validate_devcontainer_usage() is False

    def test_get_violations_none(self):
        """Test getting violations when all compliant."""
        validator = GuardrailsValidator()
        with patch.object(validator, "check_compliance", return_value={
            "package_manager_supported": True,
            "venv_properly_created": True,
            "git_operations_available": True,
            "temp_security_compliant": True,
            "devcontainer_usage": True,
        }), patch.object(validator, "validate_baseline_requirements", return_value={
            "python_package_management": True,
            "venv_management": True,
            "filesystem_operations": True,
            "temporary_files": True,
            "development_environment": True,
        }):
            violations = validator.get_violations()
            assert violations == []

    def test_get_violations_some(self):
        """Test getting violations when some not compliant."""
        validator = GuardrailsValidator()
        with patch.object(validator, "check_compliance", return_value={
            "package_manager_supported": False,
            "venv_properly_created": True,
            "git_operations_available": False,
            "temp_security_compliant": True,
            "devcontainer_usage": True,
        }), patch.object(validator, "validate_baseline_requirements", return_value={
            "python_package_management": True,
            "venv_management": True,
            "filesystem_operations": True,
            "temporary_files": True,
            "development_environment": True,
        }):
            violations = validator.get_violations()
            expected = [
                "Package manager not supported by guardrails",
                "Git operations not available in repository",
            ]
            assert violations == expected

    def test_enforce_guardrails_no_violations(self):
        """Test enforcing guardrails when no violations."""
        validator = GuardrailsValidator()
        with patch.object(validator, "get_violations", return_value=[]):
            # Should not raise
            validator.enforce_guardrails()

    def test_enforce_guardrails_with_violations(self):
        """Test enforcing guardrails when violations exist."""
        validator = GuardrailsValidator()
        violations = ["Test violation"]
        with patch.object(validator, "get_violations", return_value=violations):
            with pytest.raises(RuntimeError, match="Guardrails violations detected"):
                validator.enforce_guardrails()