# Contributing to Jamf Connect Monitor

First off, thank you for considering contributing to Jamf Connect Monitor! It's people like you that make this project better for the entire macOS administrator community.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Pull Request Process](#pull-request-process)
- [Style Guide](#style-guide)
- [Testing](#testing)

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## Getting Started

### Prerequisites

- macOS 10.14 or later
- Jamf Connect installed
- Jamf Pro access (for testing)
- Basic knowledge of Bash scripting
- Understanding of Jamf Pro Extension Attributes

### Development Environment

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/yourusername/jamf-connect-monitor.git
   cd jamf-connect-monitor
   ```
3. Set up the development environment:
   ```bash
   ./scripts/dev-setup.sh
   ```

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find that the bug has already been reported. When you create a bug report, please include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples**
- **Include macOS version and Jamf Connect version**
- **Include relevant log files**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- **Use a clear and descriptive title**
- **Provide a step-by-step description of the suggested enhancement**
- **Provide specific examples to demonstrate the enhancement**
- **Explain why this enhancement would be useful**

### Your First Code Contribution

Unsure where to begin? You can start by looking through these beginner-friendly issues:

- `good-first-issue` - issues which should only require a few lines of code
- `help-wanted` - issues which should be a bit more involved

### Pull Requests

1. Follow the [style guide](#style-guide)
2. Include tests for any new functionality
3. Update documentation as needed
4. Ensure all tests pass
5. Include a clear commit message

## Development Setup

### Local Testing

```bash
# Create test environment
sudo ./scripts/create-test-env.sh

# Run tests
sudo ./scripts/run-tests.sh

# Test package creation
sudo ./scripts/package_creation_script.sh build
```

### Testing with Jamf Pro

1. Set up a test computer in Jamf Pro
2. Deploy your changes via policy
3. Verify functionality with Extension Attribute
4. Check logs for proper operation

## Pull Request Process

1. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the style guide

3. **Test thoroughly**:
   - Run local tests
   - Test on actual Jamf Connect system
   - Verify Extension Attribute functionality
   - Check all log outputs

4. **Update documentation** if needed:
   - Update README.md
   - Update CHANGELOG.md
   - Add/update code comments

5. **Commit with clear messages**:
   ```bash
   git commit -m "Add feature: brief description
   
   Longer explanation of what this commit does and why.
   Fixes #123"
   ```

6. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request** with:
   - Clear title and description
   - Reference to any related issues
   - Test results and verification steps

## Style Guide

### Bash Scripts

- Use `#!/bin/bash` shebang for all scripts
- Use 4-space indentation
- Include comprehensive error handling
- Add logging for all major operations
- Use meaningful variable names
- Include function documentation
- Follow existing code patterns

### Example:
```bash
#!/bin/bash

# Function: check_admin_status
# Description: Checks if user has admin privileges
# Parameters: $1 - username to check
# Returns: 0 if admin, 1 if not admin
check_admin_status() {
    local username="$1"
    
    if [[ -z "$username" ]]; then
        log_message "ERROR" "Username parameter required"
        return 1
    fi
    
    if dsmemberutil checkmembership -U "$username" -G admin | grep -q "user is a member"; then
        log_message "INFO" "User $username has admin privileges"
        return 0
    else
        log_message "INFO" "User $username does not have admin privileges"
        return 1
    fi
}
```

### Documentation

- Use clear, concise language
- Include code examples where appropriate
- Update documentation with any functional changes
- Follow Markdown best practices

### Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit first line to 72 characters or less
- Reference issues and pull requests when appropriate

## Testing

### Required Tests

Before submitting a pull request, ensure:

1. **Script functionality tests**:
   - Monitor script executes without errors
   - LaunchDaemon loads and runs properly
   - Extension Attribute returns expected results

2. **Integration tests**:
   - Jamf Connect elevation detection works
   - Admin removal functions correctly
   - Notifications send properly

3. **Edge case tests**:
   - Handles missing files gracefully
   - Proper error handling for invalid inputs
   - Works with various Jamf Connect configurations

### Test Environment

```bash
# Set up test environment
sudo ./scripts/test-setup.sh

# Run all tests
sudo ./scripts/run-all-tests.sh

# Clean up test environment
sudo ./scripts/test-cleanup.sh
```

## Release Process

1. Update version numbers in relevant files
2. Update CHANGELOG.md with new features/fixes
3. Create release branch
4. Test thoroughly on multiple systems
5. Submit pull request to main
6. Tag release after merge
7. Create GitHub release with binaries

## Getting Help

- **GitHub Discussions**: Ask questions about development
- **GitHub Issues**: Report bugs or request features
- **Wiki**: Check documentation and examples

Thank you for contributing to Jamf Connect Monitor! 🎉