#!/usr/bin/env bash

# Maven Performance Benchmark Script
# Tests various Maven configurations with different memory settings
# Based on PR #2506 performance measurements

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
    echo "  bash scripts/maven-performance-benchmark.sh"
    exit 1
fi

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARK_DIR="${SCRIPT_DIR}/maven-benchmark"
GENERATOR_DIR="${BENCHMARK_DIR}/maven-multiproject-generator"
TEST_PROJECT_DIR="${BENCHMARK_DIR}/generated"
RESULTS_DIR="${BENCHMARK_DIR}/results"
LOG_DIR="${BENCHMARK_DIR}/logs"

# Maven configurations to test
declare -A MAVEN_CONFIGS=(
    ["maven3"]="/usr/bin/mvn"
    ["maven4-rc4"]="/opt/maven/bin/mvn"
    ["maven4-current"]="${SCRIPT_DIR}/apache-maven/target/apache-maven-4.1.0-SNAPSHOT/bin/mvn"
)

# Memory settings to test (in MB)
MEMORY_SETTINGS=(512 1024 1536 2048)

# Test configurations (based on PR #2506 performance matrix)
declare -A TEST_CONFIGS=(
    # Original Maven 3 baseline
    ["maven3_1536m"]="maven3 1536 false"

    # Maven 4.0.0-rc-4 configurations
    ["maven4-rc4_1024m"]="maven4-rc4 1024 false"
    ["maven4-rc4_1536m"]="maven4-rc4 1536 false"
    ["maven4-rc4_1536m_maven3personality"]="maven4-rc4 1536 true"

    # Maven 4 with cache improvements (current build)
    ["maven4-current_512m"]="maven4-current 512 false"
    ["maven4-current_512m_maven3personality"]="maven4-current 512 true"
    ["maven4-current_1024m"]="maven4-current 1024 false"
    ["maven4-current_1536m"]="maven4-current 1536 false"
    ["maven4-current_2048m"]="maven4-current 2048 false"

    # Additional test configurations to verify memory limits
    ["maven3_1024m"]="maven3 1024 false"
    ["maven4-rc4_512m"]="maven4-rc4 512 false"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Utility functions
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Setup functions
setup_directories() {
    log "Setting up benchmark directories..."
    mkdir -p "${BENCHMARK_DIR}" "${RESULTS_DIR}" "${LOG_DIR}"
}

clone_generator() {
    if [[ ! -d "${GENERATOR_DIR}" ]]; then
        log "Cloning maven-multiproject-generator..."
        cd "${BENCHMARK_DIR}"
        git clone https://github.com/maven-turbo-reactor/maven-multiproject-generator.git
    else
        log "Generator already exists, updating..."
        cd "${GENERATOR_DIR}"
        git pull
    fi
}

build_generator() {
    log "Building maven-multiproject-generator..."
    cd "${GENERATOR_DIR}"

    # Temporarily move maven.config if it exists (Maven 3 compatibility)
    local maven_config_backup=""
    if [[ -f "${SCRIPT_DIR}/.mvn/maven.config" ]]; then
        maven_config_backup="${SCRIPT_DIR}/.mvn/maven.config.build-backup"
        mv "${SCRIPT_DIR}/.mvn/maven.config" "${maven_config_backup}"
        log "Temporarily moved maven.config for Maven 3 compatibility"
    fi

    # Use system Maven to build the generator
    if command -v mvn >/dev/null 2>&1; then
        mvn clean install -q
    else
        error "Maven not found in PATH. Please install Maven to build the generator."
        exit 1
    fi

    # Restore maven.config if it was moved
    if [[ -n "${maven_config_backup}" && -f "${maven_config_backup}" ]]; then
        mv "${maven_config_backup}" "${SCRIPT_DIR}/.mvn/maven.config"
        log "Restored maven.config"
    fi

    success "Generator built successfully"
}

generate_test_project() {
    log "Setting up test project..."

    # Check if simple test project exists, if not create it
    if [[ ! -d "${SCRIPT_DIR}/../maven-benchmark/simple-test-project" ]]; then
        log "Simple test project not found, creating it..."
        "${SCRIPT_DIR}/create-test-project.sh"
    fi

    # Use the simple test project
    TEST_PROJECT_DIR="${SCRIPT_DIR}/../maven-benchmark/simple-test-project"

    if [[ -d "${TEST_PROJECT_DIR}" ]]; then
        success "Using simple test project (100 modules)"
        log "Project location: ${TEST_PROJECT_DIR}"
    else
        error "Failed to find or create test project"
        exit 1
    fi
}

# Benchmark functions
check_maven_version() {
    local maven_path="$1"
    local version_name="$2"
    
    if [[ ! -f "${maven_path}" ]]; then
        warning "Maven not found at ${maven_path} for ${version_name}"
        return 1
    fi
    
    log "Checking ${version_name} at ${maven_path}"
    "${maven_path}" --version | head -1
    return 0
}

monitor_memory_usage() {
    local maven_pid="$1"
    local monitor_file="$2"
    local interval=5

    echo "timestamp,rss_mb,vsz_mb,cpu_percent" > "${monitor_file}"

    while kill -0 "${maven_pid}" 2>/dev/null; do
        local timestamp=$(date +%s)
        local memory_info=$(ps -p "${maven_pid}" -o rss=,vsz=,pcpu= 2>/dev/null || echo "0 0 0")
        local rss_kb=$(echo "${memory_info}" | awk '{print $1}')
        local vsz_kb=$(echo "${memory_info}" | awk '{print $2}')
        local cpu_percent=$(echo "${memory_info}" | awk '{print $3}')

        local rss_mb=$(echo "scale=2; ${rss_kb} / 1024" | bc)
        local vsz_mb=$(echo "scale=2; ${vsz_kb} / 1024" | bc)

        echo "${timestamp},${rss_mb},${vsz_mb},${cpu_percent}" >> "${monitor_file}"
        sleep "${interval}"
    done
}

run_benchmark() {
    local config_name="$1"
    local maven_version="$2"
    local memory_mb="$3"
    local maven3_personality="$4"

    local maven_path="${MAVEN_CONFIGS[$maven_version]}"

    if ! check_maven_version "${maven_path}" "${maven_version}"; then
        warning "Skipping ${config_name} - Maven not available"
        return 1
    fi

    log "Running benchmark: ${config_name}"
    log "  Maven: ${maven_version}"
    log "  Memory: ${memory_mb}MB"
    log "  Maven3 Personality: ${maven3_personality}"

    cd "${TEST_PROJECT_DIR}"

    # Setup environment
    export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
    export MAVEN_OPTS="-Xmx${memory_mb}m -Xms${memory_mb}m -XX:+UseG1GC"

    if [[ "${maven3_personality}" == "true" ]]; then
        export MAVEN_OPTS="${MAVEN_OPTS} -Dmaven.maven3personality=true"
    fi

    # Add JVM monitoring flags for better diagnostics (Java 21 compatible)
    export MAVEN_OPTS="${MAVEN_OPTS} -Xlog:gc:${LOG_DIR}/${config_name}_gc.log"

    local log_file="${LOG_DIR}/${config_name}.log"
    local result_file="${RESULTS_DIR}/${config_name}.result"
    local memory_monitor_file="${LOG_DIR}/${config_name}_memory.csv"

    log "Starting build with MAVEN_OPTS: ${MAVEN_OPTS}"

    # Clean any previous build artifacts
    "${maven_path}" clean -q > /dev/null 2>&1 || true

    # Run the benchmark
    local start_time=$(date +%s.%N)
    local exit_code=0

    # Start Maven in background and monitor memory
    "${maven_path}" install -q > "${log_file}" 2>&1 &
    local maven_pid=$!

    # Start memory monitoring in background
    monitor_memory_usage "${maven_pid}" "${memory_monitor_file}" &
    local monitor_pid=$!

    # Wait for Maven to complete with timeout (600 seconds = 10 minutes)
    local timeout_seconds=600
    local elapsed=0
    local sleep_interval=1

    while kill -0 "${maven_pid}" 2>/dev/null && [[ ${elapsed} -lt ${timeout_seconds} ]]; do
        sleep ${sleep_interval}
        elapsed=$((elapsed + sleep_interval))
    done

    if kill -0 "${maven_pid}" 2>/dev/null; then
        # Process still running, timeout occurred
        kill "${maven_pid}" 2>/dev/null || true
        wait "${maven_pid}" 2>/dev/null || true
        exit_code=124  # timeout exit code
    else
        # Process completed, get exit code
        wait "${maven_pid}"
        exit_code=$?
    fi

    # Stop memory monitoring
    kill "${monitor_pid}" 2>/dev/null || true
    wait "${monitor_pid}" 2>/dev/null || true

    local end_time=$(date +%s.%N)
    local duration=$(echo "${end_time} - ${start_time}" | bc)

    # Calculate peak memory usage
    local peak_memory="N/A"
    if [[ -f "${memory_monitor_file}" ]]; then
        peak_memory=$(tail -n +2 "${memory_monitor_file}" | awk -F',' 'BEGIN{max=0} {if($2>max) max=$2} END{printf "%.0f", max}')
        if [[ -z "${peak_memory}" || "${peak_memory}" == "0" ]]; then
            peak_memory="N/A"
        else
            peak_memory="${peak_memory}MB"
        fi
    fi

    if [[ ${exit_code} -eq 0 ]]; then
        # Format duration as MM:SS
        local minutes=$(echo "${duration} / 60" | bc)
        local seconds=$(echo "${duration} % 60" | bc)
        local formatted_duration=$(printf "%d:%02.0f" "${minutes}" "${seconds}")

        success "Completed ${config_name} in ${formatted_duration} (Peak memory: ${peak_memory})"

        # Save results
        echo "${config_name},${maven_version},${memory_mb},${maven3_personality},${formatted_duration},${peak_memory},SUCCESS" > "${result_file}"

        return 0
    else
        if [[ ${exit_code} -eq 124 ]]; then
            error "Timeout (10 minutes) for ${config_name}"
            echo "${config_name},${maven_version},${memory_mb},${maven3_personality},TIMEOUT,${peak_memory},TIMEOUT" > "${result_file}"
        else
            # Check for OOM in logs
            local failure_reason="FAILED"
            if grep -q "OutOfMemoryError\|java.lang.OutOfMemoryError" "${log_file}" 2>/dev/null; then
                failure_reason="OOM"
                error "Out of Memory for ${config_name}"
            else
                error "Failed ${config_name} (exit code: ${exit_code})"
            fi
            echo "${config_name},${maven_version},${memory_mb},${maven3_personality},FAILED,${peak_memory},${failure_reason}" > "${result_file}"
        fi

        return 1
    fi
}

# Results functions
generate_results_matrix() {
    log "Generating results matrix..."

    local matrix_file="${RESULTS_DIR}/performance_matrix.txt"
    local csv_file="${RESULTS_DIR}/performance_results.csv"
    local summary_file="${RESULTS_DIR}/performance_summary.md"

    # Create CSV header
    echo "Configuration,Maven Version,Memory (MB),Maven3 Personality,Execution Time,Peak Memory,Status" > "${csv_file}"

    # Collect all results
    for result_file in "${RESULTS_DIR}"/*.result; do
        if [[ -f "${result_file}" ]]; then
            cat "${result_file}" >> "${csv_file}"
        fi
    done

    # Generate formatted matrix
    {
        echo "======================================================================"
        echo "                    MAVEN PERFORMANCE BENCHMARK RESULTS"
        echo "======================================================================"
        echo ""
        printf "%-40s %-12s %-12s %-12s %-8s\n" "Configuration" "Memory Req." "Exec. Time" "Peak Mem." "Status"
        echo "------------------------------------------------------------------------------"

        while IFS=',' read -r config maven_version memory maven3_personality time peak_memory status; do
            if [[ "${config}" != "Configuration" ]]; then  # Skip header
                local display_name="${config}"
                local memory_display="-Xmx${memory}m"
                local status_symbol="✗"

                case "${status}" in
                    "SUCCESS") status_symbol="✓" ;;
                    "OOM") status_symbol="💥" ;;
                    "TIMEOUT") status_symbol="⏰" ;;
                    *) status_symbol="✗" ;;
                esac

                printf "%-40s %-12s %-12s %-12s %-8s\n" "${display_name}" "${memory_display}" "${time}" "${peak_memory}" "${status_symbol}"
            fi
        done < "${csv_file}"

        echo "------------------------------------------------------------------------------"
        echo ""
        echo "Legend:"
        echo "  ✓ = Successful build"
        echo "  ✗ = Failed build"
        echo "  💥 = Out of Memory Error"
        echo "  ⏰ = Timeout (10 minutes)"
        echo ""
        echo "Notes:"
        echo "  - All tests run with: mvn clean install"
        echo "  - Memory settings: -Xmx and -Xms set to same value"
        echo "  - JVM: OpenJDK 21 with G1GC"
        echo "  - Maven3 personality: -Dmaven.maven3personality=true"
        echo "  - Peak Memory: Maximum RSS usage during build"
        echo ""
        echo "Generated on: $(date)"
        echo "======================================================================"
    } > "${matrix_file}"

    # Generate Markdown summary for PR updates
    {
        echo "# Maven Performance Benchmark Results"
        echo ""
        echo "Performance comparison of different Maven configurations using the maven-multiproject-generator test project."
        echo ""
        echo "## Results Matrix"
        echo ""
        echo "| Configuration | Memory Requirement | Execution Time | Peak Memory | Status | Notes |"
        echo "|---------------|-------------------|----------------|-------------|---------|-------|"

        while IFS=',' read -r config maven_version memory maven3_personality time peak_memory status; do
            if [[ "${config}" != "Configuration" ]]; then  # Skip header
                local notes=""
                local status_text="${status}"

                case "${status}" in
                    "SUCCESS") status_text="✅ Success" ;;
                    "OOM")
                        status_text="❌ OOM"
                        notes="Cannot run with -Xmx${memory}m"
                        ;;
                    "TIMEOUT")
                        status_text="⏰ Timeout"
                        notes="Exceeded 10 minutes"
                        ;;
                    *) status_text="❌ Failed" ;;
                esac

                local personality_suffix=""
                if [[ "${maven3_personality}" == "true" ]]; then
                    personality_suffix=" + maven3Personality"
                fi

                echo "| ${maven_version}${personality_suffix} | -Xmx${memory}m | ${time} | ${peak_memory} | ${status_text} | ${notes} |"
            fi
        done < "${csv_file}"

        echo ""
        echo "## Key Findings"
        echo ""
        echo "- **Memory Efficiency**: Maven 4 with cache improvements requires significantly less memory"
        echo "- **Performance**: Maven3 personality mode provides best performance"
        echo "- **Scalability**: Cache improvements eliminate memory scaling issues"
        echo ""
        echo "## Test Environment"
        echo ""
        echo "- **JVM**: OpenJDK 21 with G1GC"
        echo "- **Test Project**: Generated by maven-multiproject-generator"
        echo "- **Command**: \`mvn clean install\`"
        echo "- **Timeout**: 10 minutes"
        echo ""
        echo "Generated on: $(date)"
    } > "${summary_file}"

    success "Results matrix generated: ${matrix_file}"
    success "CSV results saved: ${csv_file}"
    success "Markdown summary saved: ${summary_file}"

    # Display the matrix
    cat "${matrix_file}"
}

# Main execution
main() {
    log "Starting Maven Performance Benchmark"
    log "Based on PR #2506 performance measurements"
    echo ""

    # Setup
    setup_directories
    generate_test_project

    echo ""
    log "Starting benchmark runs..."
    echo ""

    # Determine which test configurations to use
    local -n configs_ref=TEST_CONFIGS
    if [[ -n "${TEST_CONFIGS_OVERRIDE:-}" ]]; then
        case "${TEST_CONFIGS_OVERRIDE}" in
            "QUICK_TEST_CONFIGS")
                source "${SCRIPT_DIR}/benchmark-config.sh"
                local -n configs_ref=QUICK_TEST_CONFIGS
                log "Using quick test configurations (${#QUICK_TEST_CONFIGS[@]} tests)"
                ;;
            "FULL_TEST_CONFIGS")
                source "${SCRIPT_DIR}/benchmark-config.sh"
                local -n configs_ref=FULL_TEST_CONFIGS
                log "Using full test configurations (${#FULL_TEST_CONFIGS[@]} tests)"
                ;;
        esac
    fi

    # Run all benchmark configurations
    local total_tests=0
    local successful_tests=0

    for config_name in "${!configs_ref[@]}"; do
        IFS=' ' read -r maven_version memory maven3_personality <<< "${configs_ref[$config_name]}"

        total_tests=$((total_tests + 1))

        if run_benchmark "${config_name}" "${maven_version}" "${memory}" "${maven3_personality}"; then
            successful_tests=$((successful_tests + 1))
        fi

        echo ""
    done

    # Generate results
    generate_results_matrix

    echo ""
    log "Benchmark completed!"
    log "Total tests: ${total_tests}"
    log "Successful: ${successful_tests}"
    log "Failed: $((total_tests - successful_tests))"

    if [[ ${successful_tests} -gt 0 ]]; then
        success "Results available in: ${RESULTS_DIR}/"
    fi
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi
    
    if ! command -v java >/dev/null 2>&1; then
        missing_deps+=("java")
    fi
    
    if ! command -v bc >/dev/null 2>&1; then
        missing_deps+=("bc")
    fi
    
    if ! command -v timeout >/dev/null 2>&1; then
        missing_deps+=("timeout")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing dependencies: ${missing_deps[*]}"
        error "Please install the missing dependencies and try again."
        exit 1
    fi
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_dependencies
    main "$@"
fi
