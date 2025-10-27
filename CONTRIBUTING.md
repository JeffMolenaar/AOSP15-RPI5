# Contributing to AOSP15-RPI5

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## How to Contribute

### Types of Contributions

We welcome:
- 🐛 **Bug fixes** - Fix issues in scripts or documentation
- 📝 **Documentation improvements** - Clarify or expand guides
- ✨ **New features** - Add helpful tools or configurations
- 🧪 **Testing** - Report hardware compatibility
- 💡 **Ideas** - Suggest improvements

### Getting Started

1. **Fork the repository**
   ```bash
   # On GitHub, click "Fork"
   git clone https://github.com/YOUR-USERNAME/AOSP15-RPI5.git
   cd AOSP15-RPI5
   ```

2. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

3. **Make your changes**
   - Follow the coding standards (see below)
   - Test your changes
   - Update documentation if needed

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "Brief description of changes"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Open a Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Describe your changes
   - Reference any related issues

## Coding Standards

### Shell Scripts

- Use bash for scripts
- Include shebang: `#!/bin/bash`
- Set error handling: `set -e`
- Use descriptive variable names in CAPS: `AOSP_DIR`
- Add comments for complex logic
- Use colored output for user messages
- Check command success before proceeding

**Example**:
```bash
#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

AOSP_DIR="${HOME}/aosp-rpi5"

echo -e "${GREEN}Starting build...${NC}"

if [ ! -d "$AOSP_DIR" ]; then
    echo -e "${RED}Error: Directory not found${NC}"
    exit 1
fi

# Your code here
```

### Device Tree

- Follow Linux kernel DTS style
- Include comprehensive comments
- Use meaningful node names
- Document all GPIO pins
- Specify compatible strings

**Example**:
```dts
/dts-v1/;
/plugin/;

/*
 * Device Tree Overlay for Component XYZ
 * Brief description of what this configures
 */

/ {
    compatible = "brcm,bcm2712";
    
    fragment@0 {
        target = <&i2c1>;
        __overlay__ {
            /* Component configuration */
        };
    };
};
```

### Documentation

- Use Markdown format
- Include table of contents for long docs
- Use code blocks with syntax highlighting
- Add examples where helpful
- Keep lines under 120 characters
- Use proper headers hierarchy

**Example**:
```markdown
# Main Title

Brief introduction.

## Section Title

Content here.

### Subsection

More details.

\`\`\`bash
# Example command
./script.sh
\`\`\`
```

## Testing Requirements

### For Scripts

Before submitting script changes:

1. **Test on clean system**
   ```bash
   # Use VM or container
   docker run -it ubuntu:22.04
   ```

2. **Test error cases**
   - Missing dependencies
   - Insufficient disk space
   - Interrupted downloads

3. **Test success path**
   - Fresh install
   - Update scenario

4. **Check exit codes**
   ```bash
   ./your-script.sh
   echo $?  # Should be 0 on success
   ```

### For Documentation

1. **Check spelling and grammar**
2. **Verify all links work**
3. **Test all commands**
4. **Review on GitHub's Markdown preview**

### For Device Tree

1. **Compile without errors**
   ```bash
   dtc -@ -I dts -O dtb -o test.dtbo overlay.dts
   ```

2. **Test on hardware** (if possible)
3. **Document testing results**

## Pull Request Guidelines

### PR Title

Use descriptive titles with prefixes:
- `fix:` - Bug fixes
- `feat:` - New features
- `docs:` - Documentation changes
- `test:` - Testing improvements
- `refactor:` - Code refactoring

**Examples**:
- `fix: Correct touch overlay GPIO pins`
- `feat: Add NVMe boot support`
- `docs: Improve troubleshooting section`

### PR Description

Include:
- **What**: What does this PR do?
- **Why**: Why is this change needed?
- **How**: How does it work?
- **Testing**: How was it tested?
- **Related**: Link to related issues

**Template**:
```markdown
## Description
Brief description of changes.

## Motivation
Why this change is needed.

## Changes
- Change 1
- Change 2

## Testing
How I tested this:
- Test 1
- Test 2

## Related Issues
Fixes #123
```

### PR Checklist

Before submitting, ensure:
- [ ] Code follows style guidelines
- [ ] Documentation is updated
- [ ] Scripts are tested
- [ ] No unnecessary files included
- [ ] Commits are meaningful
- [ ] PR description is complete

## Commit Messages

### Format

```
type: Brief description (50 chars max)

Detailed explanation if needed (wrap at 72 chars).
Include motivation and impact.

Fixes #issue_number
```

### Types

- `fix` - Bug fixes
- `feat` - New features
- `docs` - Documentation
- `style` - Formatting
- `refactor` - Code restructuring
- `test` - Testing
- `chore` - Maintenance

### Examples

**Good commits**:
```
fix: Correct I2C address in touch overlay

The touch controller uses address 0x38, not 0x14.
This fixes touch not working on ED-HMI3010-101C.

Fixes #42
```

```
feat: Add support for multiple display sizes

Adds device tree overlays for 7" and 5" displays.
Updated build helper to select display during setup.
```

**Bad commits**:
```
Update file
Fixed stuff
WIP
```

## Code Review Process

1. **Automated checks** run on PR
2. **Maintainers review** within 1-7 days
3. **Address feedback** if any
4. **Approval** from maintainer
5. **Merge** to main branch

### Review Criteria

Reviewers check:
- Code quality and style
- Functionality and correctness
- Documentation completeness
- Test coverage
- Security implications
- Breaking changes

## Issue Reporting

### Before Opening an Issue

1. **Search existing issues** - May already be reported
2. **Check documentation** - Solution might be documented
3. **Test on latest version** - May already be fixed

### Opening an Issue

Use appropriate template:

**Bug Report**:
```markdown
**Describe the bug**
Clear description of the problem.

**To Reproduce**
Steps to reproduce:
1. Step 1
2. Step 2

**Expected behavior**
What should happen.

**Actual behavior**
What actually happens.

**Environment**
- OS: Ubuntu 22.04
- Hardware: 16GB RAM, 8 cores
- Version: Latest main branch

**Logs**
\`\`\`
Relevant log output
\`\`\`

**Additional context**
Any other information.
```

**Feature Request**:
```markdown
**Feature description**
What feature do you want?

**Motivation**
Why is this useful?

**Possible implementation**
How might this work?

**Alternatives**
Other approaches considered?
```

## Development Setup

### Prerequisites

- Linux system (Ubuntu 22.04 recommended)
- Git installed
- Text editor (VS Code, vim, etc.)
- shellcheck (for script validation)

### Setting Up Development Environment

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/AOSP15-RPI5.git
cd AOSP15-RPI5

# Add upstream remote
git remote add upstream https://github.com/JeffMolenaar/AOSP15-RPI5.git

# Create branch
git checkout -b my-feature

# Install shellcheck for script validation
sudo apt install shellcheck

# Validate scripts
shellcheck *.sh
```

### Keeping Your Fork Updated

```bash
# Fetch upstream changes
git fetch upstream

# Merge into your main branch
git checkout main
git merge upstream/main

# Update your feature branch
git checkout my-feature
git rebase main
```

## Documentation Contributions

### Areas Needing Documentation

- Hardware compatibility reports
- Additional display configurations
- Performance benchmarks
- Custom feature guides
- Translation to other languages

### Documentation Style

- Clear and concise
- Assume beginner knowledge
- Include examples
- Use screenshots where helpful
- Test all commands before documenting

## Hardware Testing

If you test on different hardware:

1. **Document your configuration**
   - Display model
   - Raspberry Pi model
   - Storage type
   - Any modifications

2. **Report results**
   - What works
   - What doesn't work
   - Performance observations
   - Any required changes

3. **Share improvements**
   - Device tree modifications
   - Configuration tweaks
   - Optimization tips

## Questions?

- **General questions**: Open a GitHub Discussion
- **Bugs**: Open an Issue
- **Security issues**: Email maintainers privately
- **Feature ideas**: Open an Issue with feature request template

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Assume good intentions

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Personal attacks
- Publishing private information

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (see LICENSE file).

## Recognition

Contributors will be:
- Listed in repository contributors
- Mentioned in release notes (for significant contributions)
- Credited in documentation (where applicable)

## Thank You!

Every contribution, no matter how small, is valuable and appreciated!

---

**Happy Contributing! 🎉**
