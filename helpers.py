#!/usr/bin/env python3
import click

from os.path import dirname, abspath, join, isfile, relpath
from os import environ, listdir, walk
from functools import cache
from subprocess import run as srun, CalledProcessError

BASE_DIR = dirname(abspath(__file__))
SCRIPT_DIR = join(BASE_DIR, 'quickstart', 'scripts')
MOD_DIR = join(BASE_DIR, 'quickstart', 'modules')

@cache
def get_modules():
    """Get modules (flat) from the modules directory."""
    modules = listdir(MOD_DIR)
    return modules

@cache
def get_scripts():
    """Get scripts (recursive with relative paths) from the scripts directory."""
    # Recursively discover scripts in subdirectories
    scripts = []
    for root, dirs, files in walk(SCRIPT_DIR):
        for file in files:
            # Skip hidden files and directories
            if file.startswith('.'):
                continue
            full_path = join(root, file)
            # Get relative path from SCRIPT_DIR (e.g., "arch/paru.sh" or "brewdump")
            rel_path = relpath(full_path, SCRIPT_DIR)
            scripts.append(rel_path)
    
    return scripts

@cache
def get_env():
    env = environ.copy()
    env['BASE_DIR'] = BASE_DIR
    return env

def cli_run(cmd: list[str], capture_output=False, dry_run=False):
    """
    Execute a command or simulate execution in dry-run mode.
    
    Args:
        cmd: Command list to execute
        capture_output: Whether to capture stdout/stderr
        dry_run: If True, print command without executing
    
    Returns:
        CompletedProcess object (or mock object in dry-run mode)
    """
    if dry_run:
        cmd_str = ' '.join(cmd)
        click.secho(f"[DRY RUN] {cmd_str}", fg='yellow')
        # Return a mock object with empty stdout/stderr for compatibility
        class MockResult:
            stdout = ""
            stderr = ""
            returncode = 0
        return MockResult()
    
    try:
        res = srun(cmd, capture_output=capture_output, text=True, check=True, env=get_env())
        return res
    except CalledProcessError as e:
        click.echo(e.stderr)
        exit(1)
    except Exception as e:
        click.echo(e)
        exit(1)

def run_all_modules(dry_run=False):
    """Run all modules, optionally in dry-run mode."""
    modules = get_modules()
    for mod in modules:
        p = join(MOD_DIR, mod)
        cli_run(['bash', p], dry_run=dry_run)


def is_valid_filename(name: str) -> bool:
    """
    Validate filename for safety and filesystem compatibility.
    
    Args:
        name: Proposed filename
        
    Returns:
        True if filename is valid, False otherwise
    """
    # Check for empty or whitespace-only
    if not name or name != name.strip():
        return False
    
    # Check length (filesystem limit)
    if len(name) > 255:
        return False
    
    # Check for path separators, parent directory references, and null bytes
    invalid_chars = ['/', '\\', '\0']
    if any(char in name for char in invalid_chars):
        return False
    
    # Check for parent directory traversal
    if '..' in name:
        return False
    
    return True


def chooseBrewfile(path):
    """
    Lists out brewfiles at path and returns selected path.
    Users can select by number (1, 2, 3...), by name, or enter a new filename to create.
    
    Returns:
        str: Full path to selected or new Brewfile
        None: If user cancels operation
    """
    try:
        files = [f for f in listdir(path) if isfile(join(path, f))]
    except FileNotFoundError:
        click.secho(f"Directory {path} not found", fg='red')
        return None
    
    # Handle empty directory - allow creation
    if not files:
        click.secho(f"No files found in {path}", fg='yellow')
        click.echo("You can create a new Brewfile by entering a filename.")
    else:
        # Display enumerated choices
        click.echo("Available Brewfiles:")
        for idx, file in enumerate(files, start=1):
            click.echo(f"  {idx}. {file}")
    
    # Prompt for selection
    while True:
        choice = click.prompt("\nSelect a Brewfile (number, name, or enter new filename)", type=str).strip()
        
        # Empty input check
        if not choice:
            click.secho("Filename cannot be empty", fg='red')
            continue
        
        # Try to parse as number
        try:
            num = int(choice)
            if 1 <= num <= len(files):
                return join(path, files[num - 1])
            else:
                click.secho(f"Number must be between 1 and {len(files)}", fg='red')
                continue
        except ValueError:
            pass  # Not a number, continue to filename checks
        
        # Check if exact filename match
        if choice in files:
            return join(path, choice)
        
        # Validate as potential new filename
        if not is_valid_filename(choice):
            click.secho(
                f"'{choice}' contains invalid characters. "
                "Avoid path separators (/, \\), parent directory references (..), and control characters.",
                fg='red'
            )
            continue
        
        # Confirm creation of new file
        confirm_msg = f"Create new Brewfile '{choice}' at '{path}/'?"
        if click.confirm(confirm_msg, default=False):
            click.secho(f"Will create new Brewfile: {choice}", fg='green')
            return join(path, choice)
        else:
            # User declined creation
            if click.confirm("Try again?", default=True):
                continue  # Retry selection
            else:
                click.secho("Operation cancelled", fg='yellow')
                return None
