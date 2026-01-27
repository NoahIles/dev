#!/usr/bin/env python3
"""
Test suite for the dev CLI tool and helper functions.

This module tests:
- Helper functions from helpers.py (is_valid_filename)
- CLI commands from dev script (list, run, and dry-run functionality)
"""

import pytest
from click.testing import CliRunner
from unittest.mock import patch, MagicMock
from os.path import join, abspath, dirname
import sys
import os

from helpers import (
    get_modules,
    get_env,
    is_valid_filename,
    BASE_DIR,
)

# Import the dev module from the script file without .py extension
# We need to use exec since the file doesn't have a .py extension
dev_script_path = abspath(join(dirname(__file__), "dev"))
if not os.path.exists(dev_script_path):
    raise ImportError(f"Dev script not found at {dev_script_path}")

# Create a module namespace and execute the dev script in it
import types
dev_module = types.ModuleType("dev")
dev_module.__file__ = dev_script_path
sys.modules["dev"] = dev_module

with open(dev_script_path, 'r') as f:
    code = compile(f.read(), dev_script_path, 'exec')
    exec(code, dev_module.__dict__)

dev = dev_module.dev


class TestIsValidFilename:
    """Test suite for is_valid_filename() validation function."""
    
    def test_valid_simple_filename(self):
        """Test that simple valid filenames pass validation."""
        assert is_valid_filename("test.txt") is True
        assert is_valid_filename("myfile") is True
        assert is_valid_filename("file-123.sh") is True
        assert is_valid_filename("under_score.py") is True
        
    def test_invalid_empty_string(self):
        """Test that empty strings are rejected."""
        assert is_valid_filename("") is False
        
    def test_invalid_whitespace_only(self):
        """Test that whitespace-only strings are rejected."""
        assert is_valid_filename("   ") is False
        assert is_valid_filename("\t") is False
        assert is_valid_filename("\n") is False
        
    def test_invalid_leading_trailing_whitespace(self):
        """Test that strings with leading/trailing whitespace are rejected."""
        assert is_valid_filename(" file.txt") is False
        assert is_valid_filename("file.txt ") is False
        assert is_valid_filename(" file.txt ") is False
        
    def test_invalid_path_separators(self):
        """Test that path separators are rejected."""
        assert is_valid_filename("path/to/file") is False
        assert is_valid_filename("path\\to\\file") is False
        assert is_valid_filename("/absolute/path") is False
        assert is_valid_filename("C:\\Windows\\path") is False
        
    def test_invalid_parent_directory_reference(self):
        """Test that parent directory references (..) are rejected."""
        assert is_valid_filename("..") is False
        assert is_valid_filename("file..txt") is False
        assert is_valid_filename("..file") is False
        assert is_valid_filename("file..") is False
        
    def test_invalid_null_byte(self):
        """Test that null bytes are rejected."""
        assert is_valid_filename("file\0name") is False
        assert is_valid_filename("\0") is False
        
    def test_invalid_long_filename(self):
        """Test that filenames longer than 255 characters are rejected."""
        long_name = "a" * 256
        assert is_valid_filename(long_name) is False
        
    def test_valid_max_length_filename(self):
        """Test that filenames of exactly 255 characters are accepted."""
        max_length_name = "a" * 255
        assert is_valid_filename(max_length_name) is True
        
    def test_valid_filename_with_dots(self):
        """Test that filenames with dots (but not ..) are valid."""
        assert is_valid_filename("file.tar.gz") is True
        assert is_valid_filename(".hidden") is True
        assert is_valid_filename("version.1.2.3") is True


class TestCLICommands:
    """Test suite for CLI commands from dev script."""
    
    def setup_method(self):
        """Set up test fixtures before each test method."""
        self.runner = CliRunner()
        
    def test_cli_group_exists(self):
        """Test that the CLI group exists and is callable."""
        result = self.runner.invoke(dev, ['--help'])
        assert result.exit_code == 0, "CLI should be callable with --help"
        assert "Development environment setup CLI" in result.output
        
    def test_list_command_exists(self):
        """Test that the list command exists."""
        result = self.runner.invoke(dev, ['list'])
        assert result.exit_code == 0, "list command should execute successfully"
        
    def test_list_command_shows_modules(self):
        """Test that list command output includes 'Modules:' section."""
        result = self.runner.invoke(dev, ['list'])
        assert "Modules:" in result.output, "Output should contain 'Modules:' header"
        
    def test_list_command_shows_scripts(self):
        """Test that list command output includes 'Scripts:' section."""
        result = self.runner.invoke(dev, ['list'])
        assert "Scripts:" in result.output, "Output should contain 'Scripts:' header"
        
    def test_run_command_with_invalid_module_shows_error(self):
        """Test that run command with invalid module name shows appropriate error."""
        result = self.runner.invoke(dev, ['run', 'nonexistent_module_12345'])
        # Should show error message for invalid module
        assert "nonexistent_module_12345 is invalid" in result.output
        assert "Modules:" in result.output, "Should show list after error"
        
    def test_run_command_with_no_arguments_shows_error(self):
        """Test that run command without arguments shows error and usage."""
        result = self.runner.invoke(dev, ['run'])
        # Should exit with error
        assert result.exit_code != 0
        assert "At least one module or script must be passed in" in result.output
        
    def test_dry_run_flag_prevents_execution(self):
        """Test that --dry-run flag shows commands without executing them."""
        # Use a valid module name that exists
        modules, scripts = get_modules()
        if modules:
            test_module = modules[0].rsplit('.', 1)[0]  # Get first module without extension
            result = self.runner.invoke(dev, ['--dry-run', 'run', test_module])
            # Should show dry run message
            assert "[DRY RUN]" in result.output, "Should show [DRY RUN] prefix"
        
    def test_dry_run_flag_with_list_command(self):
        """Test that list command works with --dry-run flag."""
        result = self.runner.invoke(dev, ['--dry-run', 'list'])
        assert result.exit_code == 0, "list command should work with --dry-run"
        assert "Modules:" in result.output
        assert "Scripts:" in result.output
        
    @patch('helpers.srun')
    def test_run_command_executes_valid_module(self, mock_srun):
        """Test that run command attempts to execute valid module."""
        # Mock the subprocess.run to avoid actual execution
        mock_result = MagicMock()
        mock_result.stdout = ""
        mock_result.stderr = ""
        mock_result.returncode = 0
        mock_srun.return_value = mock_result
        
        modules, scripts = get_modules()
        if modules:
            test_module = modules[0].rsplit('.', 1)[0]  # Get first module without extension
            result = self.runner.invoke(dev, ['run', test_module])
            # Should attempt to execute bash command
            assert mock_srun.called, "Should call subprocess.run"
            # Check that bash was called
            call_args = mock_srun.call_args[0][0]
            assert call_args[0] == 'bash', "Should execute with bash"
            
    def test_run_command_accepts_multiple_modules(self):
        """Test that run command accepts multiple module/script names."""
        # Test with invalid modules to avoid execution, just check argument parsing
        result = self.runner.invoke(dev, ['run', 'invalid1', 'invalid2'])
        # Both should be reported as invalid
        assert "invalid1 is invalid" in result.output
        assert "invalid2 is invalid" in result.output


class TestCLIIntegration:
    """Integration tests for CLI tool."""
    
    def setup_method(self):
        """Set up test fixtures before each test method."""
        self.runner = CliRunner()
        
    def test_help_shows_all_commands(self):
        """Test that help output shows all available commands."""
        result = self.runner.invoke(dev, ['--help'])
        assert result.exit_code == 0
        # Check for key commands
        assert "list" in result.output
        assert "run" in result.output
        assert "install" in result.output
        assert "brewdump" in result.output
        
    def test_dry_run_flag_in_help(self):
        """Test that --dry-run flag is documented in help."""
        result = self.runner.invoke(dev, ['--help'])
        assert "--dry-run" in result.output
        assert "Show what would be executed" in result.output or "without running" in result.output


if __name__ == '__main__':
    pytest.main([__file__, '-v'])
