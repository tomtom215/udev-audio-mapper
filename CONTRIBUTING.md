# Contributing to udev-audio-mapper

First off, thank you for considering contributing to udev-audio-mapper! It's people like you that make this tool better for everyone in the Linux audio community.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Device Compatibility Reports](#device-compatibility-reports)
  - [Code Contributions](#code-contributions)
- [Style Guidelines](#style-guidelines)
  - [Git Commit Messages](#git-commit-messages)
  - [Bash Style Guidelines](#bash-style-guidelines)
  - [Documentation Guidelines](#documentation-guidelines)
- [Pull Request Process](#pull-request-process)
- [Development Setup](#development-setup)
- [Community](#community)

## Code of Conduct

This project adheres to a Code of Conduct that expects all participants to be respectful, considerate, and constructive. By participating, you are expected to uphold this code. This project is licensed under the Apache License 2.0, and by contributing, you agree that your contributions will be licensed under the same license.

## How Can I Contribute?

### Reporting Bugs

This section guides you through submitting a bug report. Following these guidelines helps maintainers and the community understand your report, reproduce the behavior, and find related reports.

**Before Submitting A Bug Report:**
- Check the [Issues](https://github.com/username/udev-audio-mapper/issues) to see if the problem has already been reported.
- If you're unable to find an open issue addressing the problem, open a new one.

**How to Submit A Good Bug Report:**
- **Use a clear and descriptive title** for the issue to identify the problem.
- **Describe the exact steps which reproduce the problem** in as many details as possible.
- **Provide specific examples** to demonstrate the steps.
- **Describe the behavior you observed after following the steps** and point out exactly what the problem is with that behavior.
- **Explain which behavior you expected to see instead and why.**
- **Include details about your Linux distribution** including the version.
- **Include logs and output** from relevant commands:
  ```bash
  cat /proc/asound/cards
  lsusb
  cat /etc/udev/rules.d/99-usb-soundcards.rules
  ```

### Suggesting Enhancements

This section guides you through submitting an enhancement suggestion, including completely new features and minor improvements to existing functionality.

**Before Submitting An Enhancement Suggestion:**
- Check if the enhancement has already been suggested in the [Issues](https://github.com/username/udev-audio-mapper/issues).
- If it has, add a comment to the existing issue instead of opening a new one.

**How to Submit A Good Enhancement Suggestion:**
- **Use a clear and descriptive title** for the issue.
- **Provide a step-by-step description of the suggested enhancement** in as many details as possible.
- **Provide specific examples to demonstrate the steps** or point to similar features in other projects.
- **Describe the current behavior** and **explain which behavior you expected to see instead** and why.
- **Explain why this enhancement would be useful** to most udev-audio-mapper users.

### Device Compatibility Reports

One of the most valuable contributions is reporting which USB audio devices work with the tool.

**How to Submit A Device Compatibility Report:**
- Use the "Device Compatibility" issue template.
- Include:
  - Manufacturer and model of the device
  - Linux distribution and kernel version
  - Whether it worked with simple rules, advanced rules, or both
  - Any special steps required

### Code Contributions

If you're interested in contributing code:

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/amazing-feature`).
3. Make your changes.
4. Commit your changes (`git commit -m 'Add some amazing feature'`).
5. Push to the branch (`git push origin feature/amazing-feature`).
6. Open a Pull Request.

## Style Guidelines

### Git Commit Messages

* Use the present tense ("Add feature", not "Added feature")
* Use the imperative mood ("Move cursor to...", not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line
* Consider starting the commit message with an applicable emoji:
  * `:bug:` for bug fixes
  * `:sparkles:` for new features
  * `:books:` for documentation changes
  * `:broom:` for code refactoring
  * `:zap:` for performance improvements

### Bash Style Guidelines

* Use 4 spaces for indentation
* Always use double brackets for conditional tests (`[[ ... ]]`)
* Use meaningful variable names
* Comment complex sections of code
* Use functions for repeated operations
* Add proper error handling
* Include usage documentation with examples

Example of good style:
```bash
# Function to validate input parameters
validate_params() {
    local param_name="$1"
    local param_value="$2"
    
    if [[ -z "$param_value" ]]; then
        echo "ERROR: $param_name cannot be empty" >&2
        return 1
    fi
    
    return 0
}
```

### Documentation Guidelines

* Use Markdown for all documentation
* Keep a clear, consistent structure
* Include examples for complex features
* Use code blocks for commands and scripts
* Keep paragraphs focused on a single topic
* Update documentation when changing functionality

## Pull Request Process

1. Ensure your code follows the style guidelines.
2. Update the README.md and documentation with details of changes if applicable.
3. The PR should work across major Linux distributions.
4. Add a clear description of the problem and solution.
5. Include any relevant issue numbers in the PR description.

## Development Setup

To set up a development environment:

1. Clone your fork of the repository
   ```bash
   git clone https://github.com/your-username/udev-audio-mapper.git
   ```

2. Set up the upstream remote
   ```bash
   git remote add upstream https://github.com/username/udev-audio-mapper.git
   ```

3. Ensure you have a test environment:
   - A Linux system (VM is fine)
   - One or more USB audio devices
   - Root access for testing udev rules

4. Testing script changes:
   ```bash
   # Run the script manually
   sudo ./usb-soundcard-mapper.sh
   
   # Check created rules
   cat /etc/udev/rules.d/99-usb-soundcards.rules
   
   # Test rule application
   sudo udevadm control --reload-rules
   ```

## Community

Join our community:
- [Issue tracker](https://github.com/username/udev-audio-mapper/issues) for bugs and features
- [Discussions](https://github.com/username/udev-audio-mapper/discussions) for questions and community support

---

Thank you for contributing to udev-audio-mapper!
