"""Tests for filesystem operations."""

import os
import shutil
import pytest
import subprocess
import tempfile
from pathlib import Path
from unittest.mock import patch, MagicMock
from install_arch.filesystem import FileSystemOps
from install_arch.config import DevConfig


class TestFileSystemOps:
    """Test cases for FileSystemOps."""

    def test_init_with_default_config(self):
        """Test initialization with default config."""
        fs_ops = FileSystemOps()
        assert isinstance(fs_ops.config, DevConfig)
        assert fs_ops.use_git is True
        assert fs_ops.tmp_base == Path("/tmp/install-arch-dev")
        assert fs_ops.secure_tmp is True

    def test_init_with_custom_config(self):
        """Test initialization with custom config."""
        config = DevConfig()
        fs_ops = FileSystemOps(config)
        assert fs_ops.config == config

    def test_create_directory(self, tmp_path):
        """Test directory creation."""
        fs_ops = FileSystemOps()
        test_dir = tmp_path / "test_dir" / "nested"

        fs_ops.create_directory(test_dir)
        assert test_dir.exists()
        assert test_dir.is_dir()

    def test_remove_directory(self, tmp_path):
        """Test directory removal."""
        fs_ops = FileSystemOps()
        test_dir = tmp_path / "test_dir"
        test_dir.mkdir()
        (test_dir / "file.txt").write_text("content")

        fs_ops.remove_directory(test_dir)
        assert not test_dir.exists()

    def test_copy_file(self, tmp_path):
        """Test file copying."""
        fs_ops = FileSystemOps()
        src_file = tmp_path / "source.txt"
        dst_file = tmp_path / "dest.txt"

        src_file.write_text("test content")

        fs_ops.copy_file(src_file, dst_file)
        assert dst_file.exists()
        assert dst_file.read_text() == "test content"

    def test_remove_file(self, tmp_path):
        """Test file removal without git."""
        config = DevConfig()
        config._config['filesystem']['use_git_ops'] = False
        fs_ops = FileSystemOps(config)

        test_file = tmp_path / "test.txt"
        test_file.write_text("content")

        fs_ops.remove_file(test_file)
        assert not test_file.exists()

    @patch('install_arch.filesystem.subprocess.run')
    def test_remove_file_with_git(self, mock_run, tmp_path):
        """Test file removal with git."""
        config = DevConfig()
        fs_ops = FileSystemOps(config)

        test_file = tmp_path / "test.txt"
        test_file.write_text("content")

        # Mock git repo check
        with patch.object(fs_ops, '_is_git_repo', return_value=True):
            fs_ops.remove_file(test_file)

            mock_run.assert_called_once_with(
                ["git", "rm", str(test_file)],
                cwd=Path.cwd(),
                capture_output=True,
                text=True,
                check=True
            )

    def test_create_secure_temp_dir(self, tmp_path):
        """Test secure temporary directory creation."""
        config = DevConfig()
        config._config['filesystem']['tmp_base_dir'] = str(tmp_path)
        fs_ops = FileSystemOps(config)

        temp_dir = fs_ops.create_secure_temp_dir("test-")
        assert temp_dir.exists()
        assert temp_dir.is_dir()
        assert temp_dir.name.startswith("test-")

        # Check permissions (should be 700)
        stat_info = temp_dir.stat()
        permissions = stat_info.st_mode & 0o777
        assert permissions == 0o700

    def test_create_temp_file(self, tmp_path):
        """Test temporary file creation."""
        config = DevConfig()
        config._config['filesystem']['tmp_base_dir'] = str(tmp_path)
        fs_ops = FileSystemOps(config)

        temp_file = fs_ops.create_temp_file(suffix=".txt", prefix="test-")
        assert temp_file.exists()
        assert temp_file.is_file()
        assert temp_file.name.startswith("test-")
        assert temp_file.name.endswith(".txt")

        # Check permissions (should be 600)
        stat_info = temp_file.stat()
        permissions = stat_info.st_mode & 0o777
        assert permissions == 0o600

    def test_cleanup_temp(self, tmp_path):
        """Test temporary file/directory cleanup."""
        fs_ops = FileSystemOps()

        # Test file cleanup
        test_file = tmp_path / "test.txt"
        test_file.write_text("content")

        fs_ops.cleanup_temp(test_file)
        assert not test_file.exists()

        # Test directory cleanup
        test_dir = tmp_path / "test_dir"
        test_dir.mkdir()
        (test_dir / "file.txt").write_text("content")

        fs_ops.cleanup_temp(test_dir)
        assert not test_dir.exists()

    @patch('install_arch.filesystem.subprocess.run')
    def test_get_repo_files(self, mock_run):
        """Test getting repository files."""
        fs_ops = FileSystemOps()

        mock_run.return_value = MagicMock(stdout="file1.py\nfile2.py\n", returncode=0)

        with patch.object(fs_ops, '_is_git_repo', return_value=True):
            files = fs_ops.get_repo_files("*.py")
            assert files == [Path("file1.py"), Path("file2.py")]

            mock_run.assert_called_once_with(
                ["git", "ls-files", "*.py"],
                cwd=Path.cwd(),
                capture_output=True,
                text=True,
                check=True
            )

    @patch('install_arch.filesystem.subprocess.run')
    def test_stage_files(self, mock_run, tmp_path):
        """Test staging files."""
        fs_ops = FileSystemOps()

        files = [tmp_path / "file1.txt", tmp_path / "file2.txt"]

        with patch.object(fs_ops, '_is_git_repo', return_value=True):
            fs_ops.stage_files(files)

            mock_run.assert_called_once_with(
                ["git", "add", str(files[0]), str(files[1])],
                cwd=Path.cwd(),
                capture_output=True,
                text=True,
                check=True
            )

    @patch('install_arch.filesystem.subprocess.run')
    def test_commit_changes(self, mock_run):
        """Test committing changes."""
        fs_ops = FileSystemOps()

        with patch.object(fs_ops, '_is_git_repo', return_value=True):
            fs_ops.commit_changes("Test commit")

            mock_run.assert_called_once_with(
                ["git", "commit", "-m", "Test commit"],
                cwd=Path.cwd(),
                capture_output=True,
                text=True,
                check=True
            )

    def test_is_git_repo_false(self):
        """Test git repo detection when not in repo."""
        fs_ops = FileSystemOps()

        with patch.object(fs_ops, '_run_git_command', side_effect=subprocess.CalledProcessError(1, 'git')):
            assert fs_ops._is_git_repo() is False