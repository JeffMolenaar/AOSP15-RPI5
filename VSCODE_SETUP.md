# Visual Studio Code Setup Guide

This guide explains how to use the AOSP15-RPI5 project with Visual Studio Code for the best development experience.

## Quick Start with VS Code

### 1. Prerequisites

Before opening the project in VS Code, ensure you have:

- **Visual Studio Code** installed ([Download here](https://code.visualstudio.com/))
- **ShellCheck** for shell script linting (optional but recommended):
  ```bash
  # Ubuntu/Debian
  sudo apt-get install shellcheck
  
  # macOS
  brew install shellcheck
  ```

### 2. Open the Project

You have two options:

**Option A: Open as Folder**
```bash
cd AOSP15-RPI5
code .
```

**Option B: Open Workspace File** (Recommended)
```bash
code AOSP15-RPI5.code-workspace
```

### 3. Install Recommended Extensions

When you first open the project, VS Code will prompt you to install recommended extensions. Click **"Install All"** to set up the complete development environment.

**Essential Extensions:**
- ShellCheck - Linting for shell scripts
- Shell Format - Formatting for shell scripts
- Bash IDE - Language support for Bash
- Markdown All in One - Markdown editing and preview
- Markdown Lint - Markdown style checking
- Device Tree - Syntax highlighting for .dts files

**Helpful Extensions:**
- GitLens - Enhanced Git features
- GitHub Pull Requests - GitHub integration
- Bash Debug - Debug shell scripts

## Using VS Code Tasks

The project includes pre-configured tasks for all common operations. Access them by:

1. Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)
2. Type "Tasks: Run Task"
3. Select the task you want to run

Or use the keyboard shortcut `Ctrl+Shift+B` to run the default build task.

### Available Tasks

#### AOSP Build Tasks
- **AOSP: Setup Environment** - Run `./setup-aosp.sh` to initialize the build environment
- **AOSP: Build Complete** - Full AOSP build (Default build task - `Ctrl+Shift+B`)
- **AOSP: Build Kernel Only** - Build only the kernel
- **AOSP: Sync Source Code** - Update AOSP sources from repositories
- **AOSP: Clean Build Output** - Clean build artifacts

#### Utility Tasks
- **AOSP: Show Build Info** - Display build configuration and status
- **AOSP: Flash to SD Card** - Flash built image to SD card (prompts for device)
- **Device Tree: Compile Touch Overlay** - Compile the device tree overlay
- **Customization: Create Boot Animation** - Generate custom boot animation

#### Quality Tasks
- **Shell: Check Scripts with ShellCheck** - Lint all shell scripts
- **Markdown: Lint All Documentation** - Check all markdown files
- **Git: Show Repository Status** - Display git status and recent commits

### Task Examples

**Build the complete AOSP:**
1. Press `Ctrl+Shift+B`
2. Wait for the build to complete (2-6 hours)

**Flash to SD card:**
1. `Ctrl+Shift+P` → "Tasks: Run Task"
2. Select "AOSP: Flash to SD Card"
3. Enter the device path (e.g., `/dev/sdc`)

**Check shell scripts:**
1. `Ctrl+Shift+P` → "Tasks: Run Task"
2. Select "Shell: Check Scripts with ShellCheck"
3. Review any linting warnings/errors

## Debugging Shell Scripts

The project includes debug configurations for all major shell scripts.

### To Debug a Script:

1. Open the script file (e.g., `setup-aosp.sh`)
2. Set breakpoints by clicking in the gutter (left of line numbers)
3. Press `F5` to start debugging
4. Select the appropriate debug configuration
5. Use the debug toolbar to step through code

**Available Debug Configurations:**
- Debug: setup-aosp.sh
- Debug: build-helper.sh
- Debug: apply-customizations-example.sh
- Debug: create-bootanimation.sh

### Debug Controls:
- `F5` - Start/Continue
- `F10` - Step Over
- `F11` - Step Into
- `Shift+F11` - Step Out
- `Shift+F5` - Stop

## File Navigation & Features

### Quick File Access
- `Ctrl+P` - Quick open file by name
- `Ctrl+Shift+F` - Search across all files
- `Ctrl+G` - Go to line number

### Markdown Preview
- `Ctrl+Shift+V` - Open markdown preview
- `Ctrl+K V` - Open preview side-by-side
- Edit any `.md` file and see live preview

### Integrated Terminal
- ``Ctrl+` `` - Toggle integrated terminal
- Terminal opens in project root
- Run any shell command directly
- Multiple terminals in split view

### Git Integration
- `Ctrl+Shift+G` - Source control view
- View changes, stage files, commit
- GitLens provides enhanced Git features
- Inline blame and history

## Workspace Settings

The `.vscode/settings.json` file configures:

### Editor Behavior
- Tab size: 4 spaces
- Format on save: enabled
- Trim trailing whitespace: enabled
- Rulers at 80 and 120 characters

### File Associations
- `.sh` files recognized as shell scripts
- `.dts`, `.dtsi` files recognized as device tree
- `Android.bp`, `Android.mk` recognized appropriately

### Linting & Formatting
- ShellCheck runs automatically on save
- Shell scripts formatted with shell-format
- Markdown formatted with markdown-all-in-one

### Search Exclusions
Excludes from search:
- `node_modules/`
- `build/`, `out/`
- `.repo/`, `aosp-rpi5/`
- Log files, compiled binaries

## Customizing Your Workspace

### Modify Workspace Settings
Edit `.vscode/settings.json` to customize workspace-specific settings.

### Add Custom Tasks
Edit `.vscode/tasks.json` to add your own tasks:

```json
{
    "label": "My Custom Task",
    "type": "shell",
    "command": "echo 'Hello World'",
    "group": "build"
}
```

### User Settings vs Workspace Settings
- **Workspace settings** (`.vscode/settings.json`) - Apply to this project only
- **User settings** - Apply to all VS Code projects
- Access user settings: `Ctrl+,` → Settings

## Keyboard Shortcuts Cheat Sheet

### Essential Shortcuts
| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+B` | Run build task |
| `Ctrl+Shift+P` | Command palette |
| `Ctrl+P` | Quick open file |
| ``Ctrl+` `` | Toggle terminal |
| `F5` | Start debugging |
| `Ctrl+Shift+F` | Search in files |
| `Ctrl+Shift+V` | Markdown preview |

### Navigation
| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+E` | Explorer view |
| `Ctrl+Shift+G` | Source control |
| `Ctrl+Shift+X` | Extensions |
| `Ctrl+G` | Go to line |
| `Ctrl+Tab` | Switch files |

### Editing
| Shortcut | Action |
|----------|--------|
| `Ctrl+/` | Toggle comment |
| `Ctrl+D` | Select next occurrence |
| `Ctrl+Shift+L` | Select all occurrences |
| `Alt+Up/Down` | Move line up/down |
| `Ctrl+Shift+K` | Delete line |

## Troubleshooting

### Extensions Not Installing
**Solution:**
1. Check internet connection
2. Try manual install from Extensions view (`Ctrl+Shift+X`)
3. Restart VS Code

### ShellCheck Not Working
**Solution:**
1. Install ShellCheck: `sudo apt-get install shellcheck`
2. Verify installation: `shellcheck --version`
3. Reload VS Code window: `Ctrl+Shift+P` → "Reload Window"

### Tasks Not Appearing
**Solution:**
1. Verify `tasks.json` is valid JSON
2. Reload window: `Ctrl+Shift+P` → "Reload Window"
3. Check terminal output for errors

### Debugging Not Working
**Solution:**
1. Install Bash Debug extension
2. Ensure script has execute permissions: `chmod +x script.sh`
3. Check launch.json configuration

### Slow Performance
**Solution:**
1. Exclude large directories from search (already configured)
2. Disable unused extensions
3. Increase VS Code memory: `code --max-memory=4096`

## Tips & Best Practices

### Working with Large Projects
- Use workspace search exclusions (already configured)
- Close unused editor tabs
- Use "Open Editors: Limit" setting

### Shell Script Development
- ShellCheck highlights issues inline
- Use format on save for consistent style
- Set breakpoints for debugging complex scripts

### Markdown Editing
- Use preview for real-time rendering
- Markdown All in One provides TOC generation
- Lint markdown for consistency

### Git Workflows
- Use GitLens for inline blame
- GitHub integration for PR reviews
- Built-in diff viewer for changes

## VS Code Extensions Details

### Installed Extensions

#### timonwong.shellcheck
Integrates ShellCheck for shell script static analysis
- Highlights errors and warnings inline
- Runs automatically on save
- Provides quick fixes for common issues

#### foxundermoon.shell-format
Formats shell scripts consistently
- Formats on save (if enabled)
- Consistent indentation and spacing
- Configurable formatting rules

#### mads-hartmann.bash-ide-vscode
Bash language support
- Syntax highlighting
- Code completion
- Symbol navigation

#### yzhang.markdown-all-in-one
Comprehensive Markdown support
- Table of contents generation
- Keyboard shortcuts
- Math support
- Auto preview

#### davidanson.vscode-markdownlint
Markdown style checking
- Enforces markdown best practices
- Inline error highlighting
- Auto-fix available

#### mshr-h.vscode-devicetree
Device Tree language support
- Syntax highlighting for .dts files
- Schema validation
- Code completion

## Project Structure in VS Code

```
AOSP15-RPI5/
├── .vscode/                      # VS Code configuration
│   ├── settings.json            # Workspace settings
│   ├── tasks.json               # Build tasks
│   ├── launch.json              # Debug configurations
│   ├── extensions.json          # Recommended extensions
│   └── README.md                # This file
├── AOSP15-RPI5.code-workspace   # VS Code workspace file
├── *.sh                          # Shell scripts (executable)
├── *.md                          # Documentation (markdown)
├── customization/                # Customization files
├── device-tree/                  # Device tree overlays
└── [other project files]
```

## Additional Resources

- [VS Code Documentation](https://code.visualstudio.com/docs)
- [VS Code Keyboard Shortcuts](https://code.visualstudio.com/shortcuts/keyboard-shortcuts-linux.pdf)
- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)
- [Markdown Guide](https://www.markdownguide.org/)
- [Git in VS Code](https://code.visualstudio.com/docs/editor/versioncontrol)

## Getting Help

- **VS Code Issues**: Check the Output panel (`Ctrl+Shift+U`)
- **Task Issues**: View terminal output when running tasks
- **Extension Issues**: Check extension output in Output panel
- **General Help**: `Ctrl+Shift+P` → "Help: Welcome"

---

**Ready to start developing? Open the workspace and start coding!** 🚀

For project-specific documentation, see:
- [README.md](../README.md) - Project overview
- [QUICKSTART.md](../QUICKSTART.md) - Quick build guide
- [BUILD_INSTRUCTIONS.md](../BUILD_INSTRUCTIONS.md) - Detailed build guide
