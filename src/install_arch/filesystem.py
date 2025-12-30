"""Filesystem operations with git integration and secure temporary directories."""

import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import List, Optional, Union

from .config import DevConfig


class FileSystemOps:
    """Filesystem operations with git integration and secure temp handling."""

    def __init__(self, config: Optional[DevConfig] = None):
        self.config = config or DevConfig()
        self.use_git = self.config.use_git_ops
        self.tmp_base = Path(self.config.tmp_base_dir)
        self.secure_tmp = self.config.use_secure_tmp

        # Ensure tmp base directory exists
        self.tmp_base.mkdir(parents=True, exist_ok=True)

    def _run_git_command(
        self, cmd: List[str], cwd: Optional[Path] = None
    ) -> subprocess.CompletedProcess:
        """Run a git command."""
        if not self.use_git:
            raise RuntimeError("Git operations disabled in configuration")

        try:
            return subprocess.run(
                ["git"] + cmd,
                cwd=cwd or Path.cwd(),
                capture_output=True,
                text=True,
                check=True,
            )
        except subprocess.CalledProcessError as e:
            print(f"Git command failed: git {' '.join(cmd)}")
            print(f"stdout: {e.stdout}")
            print(f"stderr: {e.stderr}")
            raise

    def move_file(self, src: Union[str, Path], dst: Union[str, Path]) -> None:
        """Move a file, using git mv if configured."""
        src_path = Path(src)
        dst_path = Path(dst)

        if self.use_git and self._is_git_repo():
            self._run_git_command(["mv", str(src_path), str(dst_path)])
        else:
            shutil.move(str(src_path), str(dst_path))

    def copy_file(self, src: Union[str, Path], dst: Union[str, Path]) -> None:
        """Copy a file."""
        shutil.copy2(str(src), str(dst))

    def remove_file(self, path: Union[str, Path]) -> None:
        """Remove a file, using git rm if configured."""
        path_obj = Path(path)

        if self.use_git and self._is_git_repo():
            self._run_git_command(["rm", str(path_obj)])
        else:
            path_obj.unlink(missing_ok=True)

    def create_directory(self, path: Union[str, Path]) -> None:
        """Create a directory."""
        Path(path).mkdir(parents=True, exist_ok=True)

    def remove_directory(self, path: Union[str, Path]) -> None:
        """Remove a directory recursively."""
        shutil.rmtree(path, ignore_errors=True)

    def _is_git_repo(self) -> bool:
        """Check if current directory is a git repository."""
        try:
            self._run_git_command(["rev-parse", "--git-dir"])
            return True
        except subprocess.CalledProcessError:
            return False

    def create_secure_temp_dir(self, prefix: str = "install-arch-") -> Path:
        """Create a secure temporary directory."""
        if self.secure_tmp:
            # Use mktemp for secure temp directory
            temp_dir = Path(tempfile.mkdtemp(prefix=prefix, dir=self.tmp_base))
            # Set restrictive permissions
            temp_dir.chmod(0o700)
            return temp_dir
        else:
            temp_dir = self.tmp_base / f"{prefix}{os.urandom(8).hex()}"
            temp_dir.mkdir(parents=True, exist_ok=True)
            return temp_dir

    def create_temp_file(self, suffix: str = "", prefix: str = "install-arch-") -> Path:
        """Create a secure temporary file."""
        if self.secure_tmp:
            fd, path = tempfile.mkstemp(suffix=suffix, prefix=prefix, dir=self.tmp_base)
            os.close(fd)  # Close the file descriptor
            temp_file = Path(path)
            temp_file.chmod(0o600)  # Restrictive permissions
            return temp_file
        else:
            temp_file = self.tmp_base / f"{prefix}{os.urandom(8).hex()}{suffix}"
            temp_file.touch()
            return temp_file

    def cleanup_temp(self, path: Union[str, Path]) -> None:
        """Clean up temporary files/directories."""
        path_obj = Path(path)
        if path_obj.exists():
            if path_obj.is_file():
                path_obj.unlink(missing_ok=True)
            else:
                shutil.rmtree(path_obj, ignore_errors=True)

    def get_repo_files(self, pattern: str = "*") -> List[Path]:
        """Get files in the repository matching a pattern."""
        if not self._is_git_repo():
            return []

        try:
            result = self._run_git_command(["ls-files", pattern])
            return [Path(line) for line in result.stdout.strip().split("\n") if line]
        except subprocess.CalledProcessError:
            return []

    def stage_files(self, files: List[Union[str, Path]]) -> None:
        """Stage files for commit."""
        if not self.use_git:
            return

        file_paths = [str(f) for f in files]
        self._run_git_command(["add"] + file_paths)

    def commit_changes(self, message: str) -> None:
        """Commit staged changes."""
        if not self.use_git:
            return

        self._run_git_command(["commit", "-m", message])
