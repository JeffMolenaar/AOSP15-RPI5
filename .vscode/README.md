# Visual Studio Code Project Configuration

This directory contains Visual Studio Code configuration files for the AOSP15-RPI5 project.

## Files Overview

### settings.json
Workspace settings that configure:
- Editor preferences (tab size, formatting, rulers)
- File associations (shell scripts, device tree files, makefiles)
- Shell script linting with ShellCheck
- Markdown formatting
- Search and file exclusions
- Git integration
- Terminal preferences

### extensions.json
Recommended VS Code extensions for this project:

**Essential Extensions:**
- **ShellCheck** (`timonwong.shellcheck`) - Shell script linting
- **Shell Format** (`foxundermoon.shell-format`) - Shell script formatting
- **Bash IDE** (`mads-hartmann.bash-ide-vscode`) - Bash language support
- **Markdown All in One** (`yzhang.markdown-all-in-one`) - Markdown support
- **Markdown Lint** (`davidanson.vscode-markdownlint`) - Markdown linting
- **Device Tree** (`mshr-h.vscode-devicetree`) - Device tree syntax support

**Helpful Extensions:**
- **GitLens** (`eamodio.gitlens`) - Enhanced Git integration
- **GitHub Pull Requests** (`github.vscode-pull-request-github`) - GitHub integration
- **Bash Debug** (`rogalmic.bash-debug`) - Bash script debugging

### tasks.json
Pre-configured tasks for common operations:

**Build Tasks:**
- `AOSP: Setup Environment` - Run setup-aosp.sh
- `AOSP: Build Complete` - Full AOSP build (default build task)
- `AOSP: Build Kernel Only` - Build kernel only
- `AOSP: Sync Source Code` - Update AOSP sources
- `AOSP: Clean Build Output` - Clean build artifacts

**Utility Tasks:**
- `AOSP: Show Build Info` - Display build information
- `AOSP: Flash to SD Card` - Flash image to SD card
- `Device Tree: Compile Touch Overlay` - Compile device tree overlay
- `Customization: Create Boot Animation` - Generate boot animation
- `Shell: Check Scripts with ShellCheck` - Lint all shell scripts
- `Markdown: Lint All Documentation` - Lint all markdown files
- `Git: Show Repository Status` - Show git status and recent commits

**Running Tasks:**
1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)
2. Type "Tasks: Run Task"
3. Select the task you want to run

Or use the keyboard shortcut `Ctrl+Shift+B` to run the default build task.

### launch.json
Debug configurations for Bash scripts:
- Debug setup-aosp.sh
- Debug build-helper.sh
- Debug apply-customizations-example.sh
- Debug create-bootanimation.sh

**Debugging:**
1. Open the script you want to debug
2. Set breakpoints by clicking in the gutter
3. Press `F5` or go to Run > Start Debugging
4. Select the appropriate debug configuration

## Getting Started

### 1. Install VS Code
Download and install Visual Studio Code from https://code.visualstudio.com/

### 2. Open the Project
```bash
# Option 1: Open folder in VS Code
code /path/to/AOSP15-RPI5

# Option 2: Open workspace file
code AOSP15-RPI5.code-workspace
```

### 3. Install Recommended Extensions
When you open the project, VS Code will prompt you to install recommended extensions. Click "Install All" to install them automatically.

Or manually install extensions:
1. Press `Ctrl+Shift+X` to open Extensions view
2. Search for the extension name
3. Click "Install"

### 4. Install ShellCheck (Required for Linting)
```bash
# Ubuntu/Debian
sudo apt-get install shellcheck

# macOS
brew install shellcheck
```

### 5. Start Using Tasks
Press `Ctrl+Shift+B` to run the default build task, or `Ctrl+Shift+P` and type "Tasks: Run Task" to see all available tasks.

## Quick Tips

### Keyboard Shortcuts
- `Ctrl+Shift+B` - Run default build task
- `Ctrl+Shift+P` - Command palette
- `F5` - Start debugging
- `Ctrl+` ` - Toggle terminal
- `Ctrl+Shift+E` - Explorer view
- `Ctrl+Shift+F` - Search across files
- `Ctrl+Shift+G` - Source control view

### Integrated Terminal
- The integrated terminal opens in the project root
- You can run any shell command directly
- Multiple terminals can be opened in split view

### File Navigation
- `Ctrl+P` - Quick file open
- `Ctrl+Shift+F` - Search in files
- `Ctrl+G` - Go to line

### Markdown Preview
- `Ctrl+Shift+V` - Open markdown preview
- `Ctrl+K V` - Open preview side-by-side

## Customization

### Workspace Settings
Edit `.vscode/settings.json` to customize workspace-specific settings.

### User Settings
For personal preferences that apply to all projects:
1. Press `Ctrl+,` to open Settings
2. Search for the setting you want to change
3. Modify as needed

### Adding Custom Tasks
Edit `.vscode/tasks.json` to add custom tasks for your workflow.

## Troubleshooting

### ShellCheck Not Working
1. Ensure ShellCheck is installed: `shellcheck --version`
2. Check the path in settings.json matches your installation
3. Reload VS Code: `Ctrl+Shift+P` > "Reload Window"

### Tasks Not Appearing
1. Ensure tasks.json is properly formatted (valid JSON)
2. Reload VS Code window
3. Check terminal output for errors

### Extensions Not Installing
1. Check internet connection
2. Try installing manually from Extensions view
3. Check VS Code logs: Help > Toggle Developer Tools > Console

## Additional Resources

- [VS Code Documentation](https://code.visualstudio.com/docs)
- [VS Code Keyboard Shortcuts](https://code.visualstudio.com/shortcuts/keyboard-shortcuts-linux.pdf)
- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)
- [Bash Debugging in VS Code](https://github.com/rogalmic/vscode-bash-debug)

## Project Structure Support

This VS Code configuration provides:
- ✅ Syntax highlighting for all file types in the project
- ✅ Linting and formatting for shell scripts
- ✅ Markdown editing and preview
- ✅ Device tree file support
- ✅ Git integration with enhanced features
- ✅ One-click build and flash operations
- ✅ Debugging support for Bash scripts
- ✅ Customizable workspace environment

Enjoy developing with VS Code! 🚀
