#!/usr/bin/env bash

# Basic functionality tests for Maven Bench
# Run with: ./tests/test-benchmark.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test functions
test_passed() {
    echo -e "${GREEN}✓${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_failed() {
    echo -e "${RED}✗${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

test_skipped() {
    echo -e "${YELLOW}⚠${NC} $1 (skipped)"
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${BLUE}Running:${NC} $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        test_passed "$test_name"
        return 0
    else
        test_failed "$test_name"
        return 1
    fi
}

# Test cases
test_scripts_exist() {
    echo "Testing script existence..."
    
    local scripts=(
        "scripts/maven-performance-benchmark.sh"
        "scripts/run-benchmark.sh"
        "scripts/demo-benchmark.sh"
        "scripts/create-test-project.sh"
        "scripts/benchmark-config.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -f "${PROJECT_ROOT}/${script}" ]]; then
            test_passed "Script exists: $script"
        else
            test_failed "Script missing: $script"
        fi
        TESTS_RUN=$((TESTS_RUN + 1))
    done
}

test_scripts_executable() {
    echo "Testing script permissions..."
    
    local scripts=(
        "scripts/maven-performance-benchmark.sh"
        "scripts/run-benchmark.sh"
        "scripts/demo-benchmark.sh"
        "scripts/create-test-project.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ -x "${PROJECT_ROOT}/${script}" ]]; then
            test_passed "Script executable: $script"
        else
            test_failed "Script not executable: $script"
        fi
        TESTS_RUN=$((TESTS_RUN + 1))
    done
}

test_documentation_exists() {
    echo "Testing documentation..."
    
    local docs=(
        "README.md"
        "docs/USAGE.md"
        "docs/CONFIGURATION.md"
        "docs/RESULTS.md"
        "docs/CONTRIBUTING.md"
    )
    
    for doc in "${docs[@]}"; do
        if [[ -f "${PROJECT_ROOT}/${doc}" ]]; then
            test_passed "Documentation exists: $doc"
        else
            test_failed "Documentation missing: $doc"
        fi
        TESTS_RUN=$((TESTS_RUN + 1))
    done
}

test_configuration_syntax() {
    echo "Testing configuration syntax..."
    
    cd "${PROJECT_ROOT}"
    
    # Test configuration file syntax
    if bash -n scripts/benchmark-config.sh; then
        test_passed "Configuration syntax valid"
    else
        test_failed "Configuration syntax invalid"
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_help_options() {
    echo "Testing help options..."
    
    cd "${PROJECT_ROOT}"
    
    # Test help option
    if scripts/run-benchmark.sh --help >/dev/null 2>&1; then
        test_passed "Help option works"
    else
        test_failed "Help option failed"
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_environment_check() {
    echo "Testing environment check..."
    
    cd "${PROJECT_ROOT}"
    
    # Test environment check (may fail if Maven not installed, but should not crash)
    if scripts/run-benchmark.sh --check >/dev/null 2>&1 || [[ $? -eq 1 ]]; then
        test_passed "Environment check runs"
    else
        test_failed "Environment check crashed"
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_project_generation() {
    echo "Testing project generation..."
    
    cd "${PROJECT_ROOT}"
    
    # Test project generation
    if scripts/create-test-project.sh >/dev/null 2>&1; then
        test_passed "Test project generation works"
        
        # Check if project was created
        if [[ -d "maven-benchmark/simple-test-project" ]]; then
            test_passed "Test project directory created"
        else
            test_failed "Test project directory not created"
        fi
        TESTS_RUN=$((TESTS_RUN + 1))
        
        # Check project structure
        if [[ -f "maven-benchmark/simple-test-project/pom.xml" ]]; then
            test_passed "Test project POM created"
        else
            test_failed "Test project POM not created"
        fi
        TESTS_RUN=$((TESTS_RUN + 1))
        
    else
        test_failed "Test project generation failed"
        TESTS_RUN=$((TESTS_RUN + 1))
    fi
}

test_shell_syntax() {
    echo "Testing shell script syntax..."
    
    cd "${PROJECT_ROOT}"
    
    local scripts=(
        "scripts/maven-performance-benchmark.sh"
        "scripts/run-benchmark.sh"
        "scripts/demo-benchmark.sh"
        "scripts/create-test-project.sh"
        "scripts/benchmark-config.sh"
    )
    
    for script in "${scripts[@]}"; do
        if bash -n "$script" 2>/dev/null; then
            test_passed "Syntax valid: $script"
        else
            test_failed "Syntax error: $script"
        fi
        TESTS_RUN=$((TESTS_RUN + 1))
    done
}

test_examples_exist() {
    echo "Testing examples..."
    
    local examples=(
        "examples/configurations/memory-stress-test.sh"
        "examples/configurations/version-comparison.sh"
        "examples/results/sample-performance-matrix.txt"
        "examples/results/sample-performance-results.csv"
    )
    
    for example in "${examples[@]}"; do
        if [[ -f "${PROJECT_ROOT}/${example}" ]]; then
            test_passed "Example exists: $example"
        else
            test_failed "Example missing: $example"
        fi
        TESTS_RUN=$((TESTS_RUN + 1))
    done
}

# Main test execution
main() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}       Maven Bench Test Suite${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
    
    # Change to project root
    cd "${PROJECT_ROOT}"
    
    # Run test suites
    test_scripts_exist
    echo ""
    
    test_scripts_executable
    echo ""
    
    test_documentation_exists
    echo ""
    
    test_shell_syntax
    echo ""
    
    test_configuration_syntax
    echo ""
    
    test_help_options
    echo ""
    
    test_environment_check
    echo ""
    
    test_project_generation
    echo ""
    
    test_examples_exist
    echo ""
    
    # Print summary
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}           Test Summary${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo "Tests run: $TESTS_RUN"
    echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed.${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
