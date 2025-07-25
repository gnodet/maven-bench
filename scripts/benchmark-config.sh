#!/usr/bin/env bash

# Maven Performance Benchmark Configuration
# Customize these settings for your environment

# Check Bash version (requires 4.0+ for associative arrays)
if [[ ${BASH_VERSION%%.*} -lt 4 ]]; then
    echo "Error: This script requires Bash 4.0 or later"
    echo "Current version: $BASH_VERSION"
    echo ""
    echo "On macOS, install newer Bash with:"
    echo "  brew install bash"
    echo "  # Then use: /opt/homebrew/bin/bash or /usr/local/bin/bash"
    echo ""
    echo "Or run with explicit bash:"
    echo "  bash scripts/run-benchmark.sh --check"
    exit 1
fi

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# Maven installations - using cached distributions
export MAVEN3_PATH="${PROJECT_ROOT}/maven-distributions/maven-3.9.9/bin/mvn"
export MAVEN4_RC4_PATH="${PROJECT_ROOT}/maven-distributions/maven-4.0.0-rc-4/bin/mvn"
export MAVEN4_CURRENT_PATH="${PROJECT_ROOT}/maven-distributions/maven-4.0.0-rc-4/bin/mvn"  # Fallback to rc-4 if current not built

# Java installation (try to detect automatically)
if [[ -n "${JAVA_HOME}" ]]; then
    export JAVA_HOME="${JAVA_HOME}"
elif [[ -d "/usr/lib/jvm/java-21-openjdk-amd64" ]]; then
    export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
elif [[ -d "/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home" ]]; then
    export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
elif [[ -d "/usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home" ]]; then
    export JAVA_HOME="/usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
else
    echo "Warning: JAVA_HOME not set and Java 21 not found in common locations"
fi

# Test project configuration
export GENERATOR_REPO="https://github.com/maven-turbo-reactor/maven-multiproject-generator.git"

# Benchmark settings
export BENCHMARK_TIMEOUT=600  # 10 minutes
export MEMORY_MONITOR_INTERVAL=5  # seconds

# Quick test configurations
declare -A QUICK_TEST_CONFIGS=(
    ["maven4-rc4_512m"]="maven4-rc4 512 false"
    ["maven4-rc4_512m_maven3personality"]="maven4-rc4 512 true"
    ["maven4-rc4_1024m"]="maven4-rc4 1024 false"
)

# Full test configurations
declare -A FULL_TEST_CONFIGS=(
    # Maven 3 baseline
    ["maven3_1024m"]="maven3 1024 false"
    ["maven3_1536m"]="maven3 1536 false"
    
    # Maven 4.0.0-rc-4
    ["maven4-rc4_512m"]="maven4-rc4 512 false"
    ["maven4-rc4_1024m"]="maven4-rc4 1024 false"
    ["maven4-rc4_1536m"]="maven4-rc4 1536 false"
    ["maven4-rc4_1536m_maven3personality"]="maven4-rc4 1536 true"
    
    # Maven 4 current (fallback to rc-4 if not available)
    ["maven4-current_512m"]="maven4-current 512 false"
    ["maven4-current_512m_maven3personality"]="maven4-current 512 true"
    ["maven4-current_1024m"]="maven4-current 1024 false"
    ["maven4-current_1536m"]="maven4-current 1536 false"
    ["maven4-current_2048m"]="maven4-current 2048 false"
)

# Colors for output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# Helper functions
check_maven_installation() {
    local maven_name="$1"
    local maven_path="$2"
    
    if [[ -f "${maven_path}" ]]; then
        echo -e "${GREEN}✓${NC} ${maven_name}: ${maven_path}"
        "${maven_path}" --version | head -1 | sed 's/^/  /'
        return 0
    else
        echo -e "${RED}✗${NC} ${maven_name}: ${maven_path} (not found)"
        return 1
    fi
}

check_environment() {
    echo "Checking Maven installations..."
    echo ""
    
    local maven3_ok=0
    local maven4_rc4_ok=0
    local maven4_current_ok=0
    
    check_maven_installation "Maven 3" "${MAVEN3_PATH}" && maven3_ok=1
    check_maven_installation "Maven 4.0.0-rc-4" "${MAVEN4_RC4_PATH}" && maven4_rc4_ok=1
    check_maven_installation "Maven 4 Current" "${MAVEN4_CURRENT_PATH}" && maven4_current_ok=1
    
    echo ""
    echo "Java installation:"
    if [[ -d "${JAVA_HOME}" ]]; then
        echo -e "${GREEN}✓${NC} Java: ${JAVA_HOME}"
        "${JAVA_HOME}/bin/java" -version 2>&1 | head -1 | sed 's/^/  /'
    else
        echo -e "${RED}✗${NC} Java: ${JAVA_HOME} (not found)"
    fi
    
    echo ""
    echo "Available test configurations:"
    if [[ ${maven3_ok} -eq 1 ]]; then
        echo -e "${GREEN}✓${NC} Maven 3 tests available"
    else
        echo -e "${YELLOW}⚠${NC} Maven 3 tests will be skipped"
    fi
    
    if [[ ${maven4_rc4_ok} -eq 1 ]]; then
        echo -e "${GREEN}✓${NC} Maven 4.0.0-rc-4 tests available"
    else
        echo -e "${YELLOW}⚠${NC} Maven 4.0.0-rc-4 tests will be skipped"
    fi
    
    if [[ ${maven4_current_ok} -eq 1 ]]; then
        echo -e "${GREEN}✓${NC} Maven 4 current tests available"
    else
        echo -e "${RED}✗${NC} Maven 4 current tests not available - using rc-4 as fallback"
    fi
}

print_usage() {
    echo "Maven Performance Benchmark Tool"
    echo ""
    echo "Usage:"
    echo "  ./maven-performance-benchmark.sh [options]"
    echo ""
    echo "Options:"
    echo "  --quick     Run quick test (subset of configurations)"
    echo "  --full      Run full test suite (all configurations)"
    echo "  --check     Check environment and available Maven installations"
    echo "  --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./maven-performance-benchmark.sh --check"
    echo "  ./maven-performance-benchmark.sh --quick"
    echo "  ./maven-performance-benchmark.sh --full"
    echo ""
    echo "Results will be saved in: ./maven-benchmark/results/"
}

# Export functions for use in main script
export -f check_maven_installation
export -f check_environment
export -f print_usage
