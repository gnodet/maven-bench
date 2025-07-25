# Contributing to Maven Bench

We welcome contributions to Maven Bench! This document provides guidelines for contributing to the project.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Guidelines](#contributing-guidelines)
- [Code Standards](#code-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Submitting Changes](#submitting-changes)

## Getting Started

### Prerequisites

- Git
- Bash 4.0+
- Java 21+
- Maven 3.x and/or 4.x
- Basic understanding of Maven and shell scripting

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
```bash
git clone https://github.com/yourusername/maven-bench.git
cd maven-bench
```

3. Add upstream remote:
```bash
git remote add upstream https://github.com/gnodet/maven-bench.git
```

## Development Setup

### Environment Setup

1. Make scripts executable:
```bash
chmod +x scripts/*.sh
```

2. Configure your environment:
```bash
cp scripts/benchmark-config.sh scripts/benchmark-config.local.sh
# Edit benchmark-config.local.sh with your local paths
```

3. Test your setup:
```bash
./scripts/run-benchmark.sh --check
```

### Development Tools

#### Shell Linting
```bash
# Install shellcheck
sudo apt install shellcheck

# Lint all scripts
find scripts/ -name "*.sh" -exec shellcheck {} \;
```

#### Testing Framework
```bash
# Install bats (Bash Automated Testing System)
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

## Contributing Guidelines

### Areas for Contribution

1. **Core Functionality**
   - New Maven version support
   - Additional metrics collection
   - Performance optimizations
   - Bug fixes

2. **Platform Support**
   - Windows compatibility
   - macOS improvements
   - Docker containerization
   - Cloud platform support

3. **Test Scenarios**
   - New test project generators
   - Custom benchmark configurations
   - Specialized performance tests
   - Regression test suites

4. **Documentation**
   - Usage examples
   - Configuration guides
   - Performance analysis tutorials
   - API documentation

5. **Tooling**
   - CI/CD improvements
   - Result visualization
   - Data analysis tools
   - Integration scripts

### Contribution Process

1. **Check existing issues** - Look for related issues or feature requests
2. **Create an issue** - Describe your proposed changes
3. **Discuss approach** - Get feedback before starting work
4. **Implement changes** - Follow coding standards
5. **Test thoroughly** - Ensure all tests pass
6. **Submit pull request** - Include detailed description

## Code Standards

### Shell Script Standards

#### Style Guide
```bash
#!/bin/bash

# Use strict error handling
set -e
set -u
set -o pipefail

# Function naming: lowercase with underscores
function_name() {
    local param1="$1"
    local param2="$2"
    
    # Use local variables
    local result=""
    
    # Quote variables
    echo "${result}"
}

# Constants: UPPERCASE
readonly CONSTANT_VALUE="value"

# Variables: lowercase
variable_name="value"
```

#### Error Handling
```bash
# Check command success
if ! command_that_might_fail; then
    error "Command failed"
    return 1
fi

# Validate parameters
if [[ $# -lt 2 ]]; then
    error "Usage: function_name param1 param2"
    return 1
fi

# Check file existence
if [[ ! -f "${file_path}" ]]; then
    error "File not found: ${file_path}"
    return 1
fi
```

#### Documentation
```bash
#!/bin/bash

# Script description
# Usage: script.sh [options]
# 
# Options:
#   --help    Show help message
#   --verbose Enable verbose output

# Function documentation
# Runs Maven benchmark with specified configuration
# Arguments:
#   $1 - Configuration name
#   $2 - Memory size in MB
#   $3 - Maven3 personality flag (true/false)
# Returns:
#   0 on success, 1 on failure
run_benchmark() {
    # Implementation
}
```

### Configuration Standards

#### Configuration Files
```bash
# Use consistent naming
export MAVEN3_PATH="/usr/bin/mvn"
export MAVEN4_PATH="/opt/maven/bin/mvn"

# Provide defaults
export BENCHMARK_TIMEOUT="${BENCHMARK_TIMEOUT:-600}"
export MEMORY_MONITOR_INTERVAL="${MEMORY_MONITOR_INTERVAL:-5}"

# Validate configuration
validate_configuration() {
    # Check required variables
    # Validate paths
    # Test tool availability
}
```

#### Test Configurations
```bash
# Use descriptive names
declare -A TEST_CONFIGS=(
    ["maven4_512m_baseline"]="maven4-current 512 false"
    ["maven4_512m_optimized"]="maven4-current 512 true"
    ["maven4_1024m_baseline"]="maven4-current 1024 false"
)
```

## Testing

### Test Structure

Create tests in the `tests/` directory:

```bash
tests/
├── test_benchmark.bats          # Main benchmark tests
├── test_configuration.bats      # Configuration tests
├── test_project_generation.bats # Project generation tests
└── helpers/
    ├── test_helper.bash         # Common test functions
    └── fixtures/                # Test data
```

### Writing Tests

#### Basic Test Structure
```bash
#!/usr/bin/env bats

# Load test helpers
load helpers/test_helper

@test "benchmark script exists and is executable" {
    [ -x "scripts/maven-performance-benchmark.sh" ]
}

@test "configuration validation works" {
    run scripts/run-benchmark.sh --check
    [ "$status" -eq 0 ]
}

@test "quick benchmark runs successfully" {
    skip_if_no_maven
    
    run scripts/run-benchmark.sh --quick
    [ "$status" -eq 0 ]
    [ -f "results/performance_matrix.txt" ]
}
```

#### Test Helpers
```bash
# helpers/test_helper.bash

# Skip test if Maven not available
skip_if_no_maven() {
    if ! command -v mvn >/dev/null 2>&1; then
        skip "Maven not available"
    fi
}

# Setup test environment
setup_test_env() {
    export TEST_MODE=true
    export BENCHMARK_TIMEOUT=60
    mkdir -p test_results
}

# Cleanup test environment
cleanup_test_env() {
    rm -rf test_results
}
```

### Running Tests

```bash
# Run all tests
bats tests/

# Run specific test file
bats tests/test_benchmark.bats

# Run with verbose output
bats --verbose-run tests/

# Run tests in parallel
bats --jobs 4 tests/
```

## Documentation

### Documentation Standards

#### README Updates
- Keep README.md concise and focused
- Update feature lists when adding functionality
- Include usage examples for new features
- Maintain consistent formatting

#### Code Documentation
```bash
# Document complex functions
# Calculates memory efficiency improvement percentage
# Arguments:
#   $1 - baseline memory usage (MB)
#   $2 - current memory usage (MB)
# Returns:
#   Improvement percentage (0-100)
calculate_memory_improvement() {
    local baseline="$1"
    local current="$2"
    
    # Validate inputs
    if [[ ! "$baseline" =~ ^[0-9]+$ ]] || [[ ! "$current" =~ ^[0-9]+$ ]]; then
        echo "0"
        return 1
    fi
    
    # Calculate improvement
    local improvement=$(echo "scale=2; ($baseline - $current) / $baseline * 100" | bc)
    echo "$improvement"
}
```

#### Configuration Documentation
- Document all configuration options
- Provide examples for different use cases
- Explain the impact of different settings
- Include troubleshooting information

### Documentation Tools

#### Generating Documentation
```bash
# Generate API documentation from comments
scripts/generate-docs.sh

# Validate markdown
markdownlint docs/*.md

# Check links
markdown-link-check docs/*.md
```

## Submitting Changes

### Pull Request Process

1. **Create feature branch**:
```bash
git checkout -b feature/your-feature-name
```

2. **Make changes**:
   - Follow coding standards
   - Add tests for new functionality
   - Update documentation

3. **Test changes**:
```bash
# Run tests
bats tests/

# Test manually
./scripts/run-benchmark.sh --check
./scripts/run-benchmark.sh --quick
```

4. **Commit changes**:
```bash
git add .
git commit -m "feat: add new feature description"
```

5. **Push to fork**:
```bash
git push origin feature/your-feature-name
```

6. **Create pull request**:
   - Use descriptive title
   - Include detailed description
   - Reference related issues
   - Add screenshots if applicable

### Commit Message Format

Use conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks

Examples:
```
feat(benchmark): add support for Maven 4.1.0
fix(config): handle missing configuration files
docs(usage): add examples for custom configurations
test(benchmark): add integration tests for memory monitoring
```

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Other (please describe)

## Testing
- [ ] Tests pass locally
- [ ] Added tests for new functionality
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
```

## Release Process

### Version Management

- Use semantic versioning (MAJOR.MINOR.PATCH)
- Tag releases with `git tag v1.0.0`
- Update CHANGELOG.md with release notes

### Release Checklist

1. Update version numbers
2. Update documentation
3. Run full test suite
4. Create release notes
5. Tag release
6. Create GitHub release

## Getting Help

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Pull Request Reviews**: Code-specific discussions

### Code Review Process

1. All changes require review
2. Address reviewer feedback
3. Maintain clean commit history
4. Ensure CI passes

Thank you for contributing to Maven Bench!
