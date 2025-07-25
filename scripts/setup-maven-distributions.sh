#!/usr/bin/env bash

# Maven Distribution Setup Script
# Downloads and caches Maven distributions locally

# Check Bash version (requires 4.0+ for associative arrays)
if [[ ${BASH_VERSION%%.*} -lt 4 ]]; then
    echo "Error: This script requires Bash 4.0 or later"
    echo "Current version: $BASH_VERSION"
    echo ""
    echo "On macOS, install newer Bash with:"
    echo "  brew install bash"
    echo "  # Then use: /opt/homebrew/bin/bash or /usr/local/bin/bash"
    exit 1
fi

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"
MAVEN_CACHE_DIR="${PROJECT_ROOT}/maven-distributions"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Maven distributions to download
declare -A MAVEN_DISTRIBUTIONS=(
    ["maven-3.9.9"]="https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz"
    ["maven-4.0.0-rc-4"]="https://archive.apache.org/dist/maven/maven-4/4.0.0-rc-4/binaries/apache-maven-4.0.0-rc-4-bin.tar.gz"
)

# Utility functions
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Download and extract Maven distribution
download_maven() {
    local name="$1"
    local url="$2"
    local filename=$(basename "$url")
    local extract_dir="${MAVEN_CACHE_DIR}/${name}"
    local download_path="${MAVEN_CACHE_DIR}/${filename}"
    
    log "Processing $name..."
    
    # Create cache directory
    mkdir -p "${MAVEN_CACHE_DIR}"
    
    # Check if already extracted
    if [[ -d "${extract_dir}" ]]; then
        success "$name already available at ${extract_dir}"
        return 0
    fi
    
    # Download if not exists
    if [[ ! -f "${download_path}" ]]; then
        log "Downloading $name from $url"
        
        if command_exists curl; then
            curl -L -o "${download_path}" "$url"
        elif command_exists wget; then
            wget -O "${download_path}" "$url"
        else
            error "Neither curl nor wget found. Please install one of them."
            return 1
        fi
        
        if [[ ! -f "${download_path}" ]]; then
            error "Failed to download $name"
            return 1
        fi
        
        success "Downloaded $name"
    else
        log "$name already downloaded"
    fi
    
    # Extract
    log "Extracting $name..."
    cd "${MAVEN_CACHE_DIR}"
    
    if tar -tzf "${filename}" >/dev/null 2>&1; then
        tar -xzf "${filename}"
        
        # Find the extracted directory (it might have a different name)
        local extracted_dir=$(tar -tzf "${filename}" | head -1 | cut -f1 -d"/")
        
        # Rename to standardized name if needed
        if [[ "${extracted_dir}" != "${name}" ]]; then
            mv "${extracted_dir}" "${name}"
        fi
        
        success "Extracted $name to ${extract_dir}"
        
        # Verify Maven binary exists
        local maven_bin="${extract_dir}/bin/mvn"
        if [[ -f "${maven_bin}" ]]; then
            chmod +x "${maven_bin}"
            success "Maven binary ready: ${maven_bin}"
            
            # Test Maven version
            log "Testing $name..."
            if "${maven_bin}" --version >/dev/null 2>&1; then
                success "$name is working correctly"
            else
                warning "$name binary exists but version check failed"
            fi
        else
            error "Maven binary not found at ${maven_bin}"
            return 1
        fi
    else
        error "Failed to extract $name - corrupted download?"
        rm -f "${download_path}"
        return 1
    fi
    
    cd "${PROJECT_ROOT}"
}

# Update benchmark configuration
update_benchmark_config() {
    local config_file="${SCRIPT_DIR}/benchmark-config.sh"
    local temp_file="${config_file}.tmp"
    
    log "Updating benchmark configuration..."
    
    # Create updated configuration
    cat > "${temp_file}" << 'EOF'
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
EOF

    # Replace the old configuration
    mv "${temp_file}" "${config_file}"
    chmod +x "${config_file}"
    
    success "Updated benchmark configuration with cached Maven paths"
}

# Create .gitignore entry for maven-distributions
update_gitignore() {
    local gitignore_file="${PROJECT_ROOT}/.gitignore"
    
    if ! grep -q "maven-distributions/" "${gitignore_file}" 2>/dev/null; then
        echo "" >> "${gitignore_file}"
        echo "# Downloaded Maven distributions" >> "${gitignore_file}"
        echo "maven-distributions/" >> "${gitignore_file}"
        success "Added maven-distributions/ to .gitignore"
    else
        log "maven-distributions/ already in .gitignore"
    fi
}

# Main execution
main() {
    log "Setting up Maven distributions cache..."
    echo ""
    
    # Check prerequisites
    if ! command_exists curl && ! command_exists wget; then
        error "Neither curl nor wget found. Please install one of them."
        echo ""
        echo "On Ubuntu/Debian: sudo apt install curl"
        echo "On macOS: curl is pre-installed"
        echo "On RHEL/CentOS: sudo yum install curl"
        exit 1
    fi
    
    # Download Maven distributions
    local total_downloads=0
    local successful_downloads=0
    
    for name in "${!MAVEN_DISTRIBUTIONS[@]}"; do
        url="${MAVEN_DISTRIBUTIONS[$name]}"
        total_downloads=$((total_downloads + 1))
        
        if download_maven "$name" "$url"; then
            successful_downloads=$((successful_downloads + 1))
        else
            error "Failed to setup $name"
        fi
        echo ""
    done
    
    # Update configuration
    update_benchmark_config
    echo ""
    
    # Update .gitignore
    update_gitignore
    echo ""
    
    # Summary
    log "Setup completed!"
    log "Total distributions: ${total_downloads}"
    log "Successfully setup: ${successful_downloads}"
    log "Failed: $((total_downloads - successful_downloads))"
    
    if [[ ${successful_downloads} -gt 0 ]]; then
        echo ""
        success "Maven distributions cached in: ${MAVEN_CACHE_DIR}"
        success "Configuration updated: ${SCRIPT_DIR}/benchmark-config.sh"
        echo ""
        echo "Next steps:"
        echo "  1. Test the setup: ./scripts/run-benchmark.sh --check"
        echo "  2. Run quick benchmark: ./scripts/run-benchmark.sh --quick"
        echo ""
        echo "Available Maven distributions:"
        for name in "${!MAVEN_DISTRIBUTIONS[@]}"; do
            local maven_path="${MAVEN_CACHE_DIR}/${name}/bin/mvn"
            if [[ -f "${maven_path}" ]]; then
                echo "  ✓ ${name}: ${maven_path}"
            fi
        done
    else
        error "No Maven distributions were successfully setup"
        exit 1
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
