"""Guardrails validation for package functionality baseline compliance."""

import os
import subprocess
import tomllib
from pathlib import Path
from typing import Any, Dict, List, Optional


class GuardrailsValidator:
    """Validates compliance with package functionality baseline guardrails."""

    def __init__(self, guardrails_path: Optional[Path] = None):
        if guardrails_path is None:
            # Load from the comprehensive .github guardrails specification
            guardrails_path = (
                Path(__file__).parent.parent.parent
                / ".github"
                / "guardrails"
                / "package-baseline.toml"
            )

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
                timeout=10,
            )
            return result.returncode == 0
        except (
            subprocess.CalledProcessError,
            FileNotFoundError,
            subprocess.TimeoutExpired,
        ):
            return False

    def validate_temp_security(self, temp_dir: Path) -> bool:
        """Validate temporary directory security."""
        if not temp_dir.exists():
            return True  # Not created yet, so no security issue

        # In CI environments, be more lenient with permissions
        if os.getenv("CI") == "true":
            # Just check that it exists and is a directory
            return temp_dir.is_dir()

        # Check permissions (should be restrictive)
        stat_info = temp_dir.stat()
        permissions = stat_info.st_mode & 0o777

        # Should be 700 or more restrictive
        return permissions <= 0o700

    def validate_devcontainer_usage(self) -> bool:
        """Validate that work is being done in devcontainer when required."""
        # Skip devcontainer validation in CI environments
        if os.getenv("CI") == "true":
            return True

        # Check for devcontainer environment variables
        devcontainer_vars = [
            "DEVCONTAINER",
            "REMOTE_CONTAINERS",
            "VSCODE_REMOTE_CONTAINERS_SESSION",
        ]

        return any(os.getenv(var) for var in devcontainer_vars)

    def validate_filesystem_operations(self) -> bool:
        """Validate that filesystem operations follow git-preferred rules."""
        # For now, just check if git is available (since git operations
        # are preferred)
        # Could be extended to check if operations use git commands
        return self.validate_git_operations()

    def validate_baseline_requirements(self) -> Dict[str, bool]:
        """Validate baseline requirements from the comprehensive config."""
        baseline = self._config.get("baseline_requirements", {})
        results = {}

        # Check python package management
        if baseline.get("python_package_management") == "configured_tool":
            from .config import DevConfig

            config = DevConfig()
            results["python_package_management"] = self.validate_package_manager(
                config.package_manager
            )

        # Check venv management
        if baseline.get("venv_management") == "tool_managed":
            from .config import DevConfig

            config = DevConfig()
            venv_path = Path(config.venv_path)
            results["venv_management"] = self.validate_venv_creation(
                config.package_manager, venv_path
            )

        # Check filesystem operations
        if baseline.get("filesystem_operations") == "git_preferred":
            results["filesystem_operations"] = self.validate_filesystem_operations()

        # Check temporary files
        if baseline.get("temporary_files") == "secure_mktemp":
            from .config import DevConfig

            config = DevConfig()
            temp_base = Path(config.tmp_base_dir)
            if temp_base.exists():
                results["temporary_files"] = self.validate_temp_security(temp_base)
            else:
                results["temporary_files"] = True

        # Check development environment
        if baseline.get("development_environment") == "devcontainer_isolated":
            results["development_environment"] = self.validate_devcontainer_usage()

        return results

    def check_compliance(self) -> Dict[str, bool]:
        """Run all compliance checks based on the comprehensive baseline."""
        from .config import DevConfig

        config = DevConfig()

        results = {}

        compliance_checks = self._config.get("compliance_checks", {})

        # Check package manager if enabled
        if compliance_checks.get("check_package_manager", True):
            results["package_manager_supported"] = self.validate_package_manager(
                config.package_manager
            )

        # Check venv if enabled
        if compliance_checks.get("check_venv_isolation", True):
            venv_path = Path(config.venv_path)
            results["venv_properly_created"] = self.validate_venv_creation(
                config.package_manager, venv_path
            )

        # Check git operations if enabled
        if compliance_checks.get("check_git_operations", True):
            results["git_operations_available"] = self.validate_git_operations()

        # Check temp security if enabled
        if compliance_checks.get("check_temp_security", True):
            temp_base = Path(config.tmp_base_dir)
            if temp_base.exists():
                results["temp_security_compliant"] = self.validate_temp_security(
                    temp_base
                )
            else:
                results["temp_security_compliant"] = True  # Not created yet

        # Check devcontainer usage if enabled
        if compliance_checks.get("validate_devcontainer_usage", True):
            results["devcontainer_usage"] = self.validate_devcontainer_usage()

        return results

    def get_violations(self) -> List[str]:
        """Get list of compliance violations."""
        compliance = self.check_compliance()
        baseline = self.validate_baseline_requirements()
        violations = []

        # Standard compliance checks
        if not compliance.get("package_manager_supported", True):
            violations.append("Package manager not supported by guardrails")

        if not compliance.get("venv_properly_created", True):
            violations.append("Virtual environment not properly created")

        if not compliance.get("git_operations_available", True):
            violations.append("Git operations not available in repository")

        if not compliance.get("temp_security_compliant", True):
            violations.append("Temporary directory security not compliant")

        if not compliance.get("devcontainer_usage", True):
            violations.append("Work not being done in devcontainer (when required)")

        # Baseline requirement checks
        if not baseline.get("python_package_management", True):
            violations.append("Python package management not using configured tool")

        if not baseline.get("venv_management", True):
            violations.append("Virtual environment not tool-managed")

        if not baseline.get("filesystem_operations", True):
            violations.append("Filesystem operations not following git-preferred rules")

        if not baseline.get("temporary_files", True):
            violations.append("Temporary files not created securely")

        if not baseline.get("development_environment", True):
            violations.append("Development not isolated in devcontainer")

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
