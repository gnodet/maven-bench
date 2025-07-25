# Configuration Reference

This document provides detailed information about configuring Maven Bench for different testing scenarios.

## Configuration Files

### Primary Configuration: `scripts/benchmark-config.sh`

This is the main configuration file that controls all aspects of the benchmark.

```bash
#!/bin/bash

# Maven Performance Benchmark Configuration
# Customize these settings for your environment

# Maven installations - update paths as needed
export MAVEN3_PATH="/usr/bin/mvn"
export MAVEN4_RC4_PATH="/opt/maven/bin/mvn"
export MAVEN4_CURRENT_PATH="${PWD}/apache-maven/target/apache-maven-4.1.0-SNAPSHOT/bin/mvn"

# Java installation
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"

# Test project configuration
export GENERATOR_REPO="https://github.com/maven-turbo-reactor/maven-multiproject-generator.git"

# Benchmark settings
export BENCHMARK_TIMEOUT=600  # 10 minutes
export MEMORY_MONITOR_INTERVAL=5  # seconds
```

## Maven Installation Paths

### Maven 3.x Configuration
```bash
# System installation
export MAVEN3_PATH="/usr/bin/mvn"

# Manual installation
export MAVEN3_PATH="/opt/apache-maven-3.9.5/bin/mvn"

# Homebrew (macOS)
export MAVEN3_PATH="/opt/homebrew/bin/mvn"
```

### Maven 4.x Configuration
```bash
# Maven 4.0.0-rc-4
export MAVEN4_RC4_PATH="/opt/apache-maven-4.0.0-rc-4/bin/mvn"

# Maven 4 built from source
export MAVEN4_CURRENT_PATH="/path/to/maven/apache-maven/target/apache-maven-4.1.0-SNAPSHOT/bin/mvn"

# Custom build location
export MAVEN4_CURRENT_PATH="/home/user/maven-build/bin/mvn"
```

## Test Configurations

### Quick Test Configurations
```bash
declare -A QUICK_TEST_CONFIGS=(
    ["maven4-current_512m"]="maven4-current 512 false"
    ["maven4-current_512m_maven3personality"]="maven4-current 512 true"
    ["maven4-current_1024m"]="maven4-current 1024 false"
)
```

### Full Test Configurations
```bash
declare -A FULL_TEST_CONFIGS=(
    # Maven 3 baseline
    ["maven3_1024m"]="maven3 1024 false"
    ["maven3_1536m"]="maven3 1536 false"
    
    # Maven 4.0.0-rc-4
    ["maven4-rc4_512m"]="maven4-rc4 512 false"
    ["maven4-rc4_1024m"]="maven4-rc4 1024 false"
    ["maven4-rc4_1536m"]="maven4-rc4 1536 false"
    ["maven4-rc4_1536m_maven3personality"]="maven4-rc4 1536 true"
    
    # Maven 4 current with cache improvements
    ["maven4-current_512m"]="maven4-current 512 false"
    ["maven4-current_512m_maven3personality"]="maven4-current 512 true"
    ["maven4-current_1024m"]="maven4-current 1024 false"
    ["maven4-current_1536m"]="maven4-current 1536 false"
    ["maven4-current_2048m"]="maven4-current 2048 false"
)
```

### Custom Configurations

#### Memory Stress Testing
```bash
declare -A MEMORY_STRESS_CONFIGS=(
    ["maven4-current_256m"]="maven4-current 256 false"
    ["maven4-current_384m"]="maven4-current 384 false"
    ["maven4-current_512m"]="maven4-current 512 false"
    ["maven4-current_768m"]="maven4-current 768 false"
    ["maven4-current_1024m"]="maven4-current 1024 false"
)
```

#### Performance Comparison
```bash
declare -A PERFORMANCE_CONFIGS=(
    ["maven3_baseline"]="maven3 1536 false"
    ["maven4-rc4_baseline"]="maven4-rc4 1536 false"
    ["maven4-rc4_optimized"]="maven4-rc4 1536 true"
    ["maven4-current_baseline"]="maven4-current 1536 false"
    ["maven4-current_optimized"]="maven4-current 1536 true"
)
```

## Environment Variables

### Core Settings
```bash
# Java configuration
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
export JAVA_OPTS="-XX:+UseG1GC"

# Maven configuration
export MAVEN_OPTS="-Xmx2g -Xms2g"

# Benchmark settings
export BENCHMARK_TIMEOUT=600
export MEMORY_MONITOR_INTERVAL=5
export BENCHMARK_DEBUG=false
```

### Advanced Settings
```bash
# Test project configuration
export TEST_PROJECT_MODULES=100
export TEST_PROJECT_DEPTH=5
export TEST_PROJECT_DIR="/custom/path/to/test/project"

# Output configuration
export RESULTS_DIR="/custom/results/path"
export LOG_DIR="/custom/logs/path"

# Parallel execution
export MAVEN_PARALLEL_THREADS=4
export MAVEN_COMPILE_FORK=true
```

## JVM Configuration

### Memory Settings
```bash
# Heap size configuration
export MAVEN_OPTS="-Xmx1024m -Xms1024m"

# Garbage collection
export MAVEN_OPTS="${MAVEN_OPTS} -XX:+UseG1GC"
export MAVEN_OPTS="${MAVEN_OPTS} -XX:MaxGCPauseMillis=200"

# GC logging (Java 21)
export MAVEN_OPTS="${MAVEN_OPTS} -Xlog:gc:gc.log"

# Memory debugging
export MAVEN_OPTS="${MAVEN_OPTS} -XX:+HeapDumpOnOutOfMemoryError"
export MAVEN_OPTS="${MAVEN_OPTS} -XX:HeapDumpPath=/tmp/maven-heap-dump.hprof"
```

### Performance Tuning
```bash
# JIT compilation
export MAVEN_OPTS="${MAVEN_OPTS} -XX:+TieredCompilation"
export MAVEN_OPTS="${MAVEN_OPTS} -XX:TieredStopAtLevel=1"

# Class loading
export MAVEN_OPTS="${MAVEN_OPTS} -XX:+UseStringDeduplication"
export MAVEN_OPTS="${MAVEN_OPTS} -XX:+UseCompressedOops"

# I/O optimization
export MAVEN_OPTS="${MAVEN_OPTS} -Djava.io.tmpdir=/tmp"
```

## Test Project Configuration

### Simple Test Project
```bash
# Module count
export TEST_PROJECT_MODULES=100

# Dependency depth
export TEST_PROJECT_DEPTH=5

# Test classes per module
export TEST_CLASSES_PER_MODULE=4

# Dependencies per module
export DEPS_PER_MODULE=5
```

### Large Test Project
```bash
# For stress testing
export TEST_PROJECT_MODULES=500
export TEST_PROJECT_DEPTH=10
export TEST_CLASSES_PER_MODULE=8
export DEPS_PER_MODULE=10
```

### Custom Test Project
```bash
# Use existing project
export TEST_PROJECT_DIR="/path/to/existing/maven/project"
export USE_EXISTING_PROJECT=true
```

## Monitoring Configuration

### Memory Monitoring
```bash
# Monitoring interval (seconds)
export MEMORY_MONITOR_INTERVAL=5

# Memory metrics to collect
export MONITOR_RSS=true
export MONITOR_VSZ=true
export MONITOR_CPU=true
```

### Logging Configuration
```bash
# Log levels
export MAVEN_LOG_LEVEL="INFO"
export BENCHMARK_LOG_LEVEL="DEBUG"

# Log file rotation
export MAX_LOG_SIZE="100M"
export MAX_LOG_FILES=10

# GC logging detail
export GC_LOG_DETAIL="gc,heap,ergo"
```

## Platform-Specific Configuration

### Linux
```bash
# Use system package manager Maven
export MAVEN3_PATH="/usr/bin/mvn"

# Java from package manager
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"

# Memory monitoring tools
export MEMORY_MONITOR_CMD="ps -p %PID% -o rss=,vsz=,pcpu="
```

### macOS
```bash
# Homebrew Maven
export MAVEN3_PATH="/opt/homebrew/bin/mvn"

# Homebrew Java
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"

# macOS memory monitoring
export MEMORY_MONITOR_CMD="ps -p %PID% -o rss=,vsz=,pcpu="
```

### Windows (WSL)
```bash
# WSL paths
export MAVEN3_PATH="/usr/bin/mvn"
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"

# Windows-specific temp directory
export JAVA_OPTS="${JAVA_OPTS} -Djava.io.tmpdir=/mnt/c/temp"
```

## Configuration Validation

### Environment Check Script
```bash
#!/bin/bash
# Add to benchmark-config.sh

validate_configuration() {
    local errors=0
    
    # Check Java
    if [[ ! -d "${JAVA_HOME}" ]]; then
        echo "ERROR: JAVA_HOME not found: ${JAVA_HOME}"
        errors=$((errors + 1))
    fi
    
    # Check Maven installations
    for maven_name in "${!MAVEN_CONFIGS[@]}"; do
        local maven_path="${MAVEN_CONFIGS[$maven_name]}"
        if [[ ! -f "${maven_path}" ]]; then
            echo "WARNING: Maven not found: ${maven_name} at ${maven_path}"
        fi
    done
    
    # Check required tools
    for tool in bc timeout ps; do
        if ! command -v "${tool}" >/dev/null 2>&1; then
            echo "ERROR: Required tool not found: ${tool}"
            errors=$((errors + 1))
        fi
    done
    
    return ${errors}
}
```

## Configuration Examples

### Development Environment
```bash
# Local development with multiple Maven versions
export MAVEN3_PATH="/opt/maven-3.9.5/bin/mvn"
export MAVEN4_RC4_PATH="/opt/maven-4.0.0-rc-4/bin/mvn"
export MAVEN4_CURRENT_PATH="/home/dev/maven-build/bin/mvn"
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
export BENCHMARK_TIMEOUT=300  # 5 minutes for quick testing
```

### CI/CD Environment
```bash
# Automated testing environment
export MAVEN3_PATH="/usr/bin/mvn"
export MAVEN4_RC4_PATH="/opt/maven/bin/mvn"
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
export BENCHMARK_TIMEOUT=1200  # 20 minutes for thorough testing
export MEMORY_MONITOR_INTERVAL=10  # Less frequent monitoring
```

### Performance Lab
```bash
# Dedicated performance testing
export MAVEN3_PATH="/opt/maven-3.9.5/bin/mvn"
export MAVEN4_RC4_PATH="/opt/maven-4.0.0-rc-4/bin/mvn"
export MAVEN4_CURRENT_PATH="/opt/maven-4.1.0-SNAPSHOT/bin/mvn"
export JAVA_HOME="/opt/jdk-21"
export BENCHMARK_TIMEOUT=3600  # 1 hour for extensive testing
export TEST_PROJECT_MODULES=1000  # Large test project
```

## Troubleshooting Configuration

### Common Issues
1. **Path not found**: Check file permissions and absolute paths
2. **Java version mismatch**: Ensure JAVA_HOME points to Java 21+
3. **Memory issues**: Adjust MAVEN_OPTS and system memory
4. **Timeout issues**: Increase BENCHMARK_TIMEOUT for large projects

### Debug Configuration
```bash
# Enable debug mode
export BENCHMARK_DEBUG=true
export MAVEN_DEBUG=true

# Verbose logging
export MAVEN_OPTS="${MAVEN_OPTS} -X"
export BENCHMARK_LOG_LEVEL="TRACE"
```
