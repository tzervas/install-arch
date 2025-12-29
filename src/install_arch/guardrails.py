"""Guardrails validation for package functionality baseline compliance."""

import os
import subprocess
import tomllib
from pathlib import Path
from typing import Dict, Any, List, Optional


class GuardrailsValidator:
    """Validates compliance with package functionality baseline guardrails."""

    def __init__(self, guardrails_path: Optional[Path] = None):
        if guardrails_path is None:
            guardrails_path = Path(__file__).parent / "package-baseline.toml"

        self.guardrails_path = guardrails_path
        self._config: Dict[str, Any] = {}

        if guardrails_path.exists():
            with open(guardrails_path, "rb") as f:
                self._config = tomllib.load(f)

    def validate_package_manager(self, tool: str) -> bool:
        """Validate that the package manager is supported."""
        supported_tools = self._config.get("tool_configuration", {}).keys()
        return tool in supported_tools

    def validate_venv_creation(self, tool: str, venv_path: Path) -> bool:
        """Validate virtual environment creation."""
        if not venv_path.exists():
            return False

        # Check if venv was created by the specified tool
        if tool == "uv":
            return (venv_path / "pyvenv.cfg").exists()
        elif tool == "pip":
            return (venv_path / "bin" / "activate").exists()
        elif tool == "poetry":
            # Poetry creates venv in its own location
            return True
        elif tool == "pipenv":
            # Pipenv creates venv in its own location
            return True

        return False

    def validate_git_operations(self) -> bool:
        """Validate that git operations are being used appropriately."""
        try:
            # Check if we're in a git repository
            result = subprocess.run(
                ["git", "rev-parse", "--git-dir"],
                capture_output=True,
                text=True,
                check=True,
                timeout=10
            )
            return result.returncode == 0
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
            return False

    def validate_temp_security(self, temp_dir: Path) -> bool:
        """Validate temporary directory security."""
        if not temp_dir.exists():
            return False

        # Check permissions (should be restrictive)
        stat_info = temp_dir.stat()
        permissions = stat_info.st_mode & 0o777

        # Should be 700 or more restrictive
        return permissions <= 0o700

    def validate_devcontainer_usage(self) -> bool:
        """Validate that work is being done in devcontainer when required."""
        # Check for devcontainer environment variables
        devcontainer_vars = [
            "DEVCONTAINER",
            "REMOTE_CONTAINERS",
            "VSCODE_REMOTE_CONTAINERS_SESSION"
        ]

        return any(os.getenv(var) for var in devcontainer_vars)

    def check_compliance(self) -> Dict[str, bool]:
        """Run all compliance checks."""
        from .config import DevConfig

        config = DevConfig()

        results = {}

        # Check package manager
        results["package_manager_supported"] = self.validate_package_manager(
            config.package_manager
        )

        # Check venv
        venv_path = Path(config.venv_path)
        results["venv_properly_created"] = self.validate_venv_creation(
            config.package_manager, venv_path
        )

        # Check git operations
        results["git_operations_available"] = self.validate_git_operations()

        # Check temp security
        temp_base = Path(config.tmp_base_dir)
        if temp_base.exists():
            results["temp_security_compliant"] = self.validate_temp_security(
                temp_base
            )
        else:
            results["temp_security_compliant"] = True  # Not created yet

        # Check devcontainer usage
        results["devcontainer_usage"] = self.validate_devcontainer_usage()

        return results

    def get_violations(self) -> List[str]:
        """Get list of compliance violations."""
        compliance = self.check_compliance()
        violations = []

        if not compliance.get("package_manager_supported", True):
            violations.append("Package manager not supported by guardrails")

        if not compliance.get("venv_properly_created", True):
            violations.append("Virtual environment not properly created")

        if not compliance.get("git_operations_available", True):
            violations.append("Git operations not available in repository")

        if not compliance.get("temp_security_compliant", True):
            violations.append("Temporary directory security not compliant")

        if not compliance.get("devcontainer_usage", True):
            violations.append(
                "Work not being done in devcontainer (when required)"
            )

        return violations

    def enforce_guardrails(self) -> None:
        """Enforce guardrails by checking compliance and raising errors if
        violated.
        """
        violations = self.get_violations()
        if violations:
            error_msg = "Guardrails violations detected:\n" + "\n".join(
                f"- {v}" for v in violations
            )
            raise RuntimeError(error_msg)
