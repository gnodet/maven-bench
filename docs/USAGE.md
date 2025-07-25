# Usage Guide

This guide provides detailed instructions for using Maven Bench to measure and analyze Maven performance.

## Table of Contents

- [Quick Start](#quick-start)
- [Environment Setup](#environment-setup)
- [Running Benchmarks](#running-benchmarks)
- [Understanding Results](#understanding-results)
- [Advanced Usage](#advanced-usage)
- [Troubleshooting](#troubleshooting)

## Quick Start

### 1. Clone and Setup
```bash
git clone https://github.com/gnodet/maven-bench.git
cd maven-bench
chmod +x scripts/*.sh
```

### 2. Check Environment
```bash
./scripts/run-benchmark.sh --check
```

This validates:
- Java 21+ installation
- Maven 3.x and/or 4.x installations
- System resources (memory, disk space)
- Required tools (bc, timeout, etc.)

### 3. Run Quick Test
```bash
./scripts/run-benchmark.sh --quick
```

This runs 3 configurations in ~5 minutes:
- `maven4-current_512m`
- `maven4-current_512m_maven3personality`
- `maven4-current_1024m`

## Environment Setup

### Prerequisites

#### Java
```bash
# Install OpenJDK 21
sudo apt install openjdk-21-jdk

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
```

#### Maven 3.x
```bash
# Install via package manager
sudo apt install maven

# Or download manually
wget https://archive.apache.org/dist/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz
tar -xzf apache-maven-3.9.5-bin.tar.gz
```

#### Maven 4.x
```bash
# Download Maven 4.0.0-rc-4
wget https://archive.apache.org/dist/maven/maven-4/4.0.0-rc-4/binaries/apache-maven-4.0.0-rc-4-bin.tar.gz
tar -xzf apache-maven-4.0.0-rc-4-bin.tar.gz -C /opt/

# Or build from source
git clone https://github.com/apache/maven.git
cd maven
mvn install -DskipTests -Drat.skip=true
```

#### System Tools
```bash
# Install required utilities
sudo apt install bc coreutils
```

### Configuration

Edit `scripts/benchmark-config.sh` to set paths:

```bash
# Maven installations
export MAVEN3_PATH="/usr/bin/mvn"
export MAVEN4_RC4_PATH="/opt/apache-maven-4.0.0-rc-4/bin/mvn"
export MAVEN4_CURRENT_PATH="/path/to/maven/bin/mvn"

# Java installation
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
```

## Running Benchmarks

### Interactive Demo
```bash
./scripts/demo-benchmark.sh
```

Provides guided tour with options:
1. Check environment
2. Run quick demo
3. Show usage instructions
4. Show key findings
5. Show generated files

### Command Line Interface

#### Environment Check
```bash
./scripts/run-benchmark.sh --check
```

#### Quick Test (3 configurations)
```bash
./scripts/run-benchmark.sh --quick
```

#### Full Test Suite (11 configurations)
```bash
./scripts/run-benchmark.sh --full
```

#### Direct Script Usage
```bash
./scripts/maven-performance-benchmark.sh
```

### Test Configurations

#### Quick Test
- `maven4-current_512m` - Maven 4 with 512MB
- `maven4-current_512m_maven3personality` - Maven 4 with 512MB + compatibility mode
- `maven4-current_1024m` - Maven 4 with 1024MB

#### Full Test
- **Maven 3**: 1024MB, 1536MB
- **Maven 4.0.0-rc-4**: 512MB, 1024MB, 1536MB (with/without maven3personality)
- **Maven 4 Current**: 512MB, 1024MB, 1536MB, 2048MB (with/without maven3personality)

## Understanding Results

### Output Files

#### Performance Matrix (`results/performance_matrix.txt`)
```
Configuration                            Memory Req.  Exec. Time   Peak Mem.    Status  
------------------------------------------------------------------------------
maven4-current_512m                     -Xmx512m     1:26         774MB        ✓     
maven4-current_512m_maven3personality   -Xmx512m     1:25         784MB        ✓     
maven4-current_1024m                    -Xmx1024m    1:24         1192MB       ✓     
```

#### CSV Data (`results/performance_results.csv`)
```csv
Configuration,Maven Version,Memory (MB),Maven3 Personality,Execution Time,Peak Memory,Status
maven4-current_512m,maven4-current,512,false,1:26,774MB,SUCCESS
```

#### Markdown Summary (`results/performance_summary.md`)
Ready-to-use markdown table for documentation and PR updates.

### Status Indicators
- ✓ **Success** - Build completed successfully
- ✗ **Failed** - Build failed (non-OOM error)
- 💥 **OOM** - Out of Memory Error
- ⏰ **Timeout** - Exceeded 10-minute limit

### Metrics Explained

#### Execution Time
- Format: `MM:SS` (minutes:seconds)
- Includes: `mvn clean install` full cycle
- Excludes: Environment setup and cleanup

#### Peak Memory
- **RSS (Resident Set Size)** - Physical memory used
- Measured every 5 seconds during build
- Peak value reported

#### Memory Requirement
- **-Xmx setting** - JVM heap limit
- **-Xms setting** - Initial heap size (same as Xmx)

## Advanced Usage

### Custom Test Projects

#### Generate Custom Project
```bash
./scripts/create-test-project.sh --modules 50 --depth 3
```

#### Use Existing Project
```bash
export TEST_PROJECT_DIR="/path/to/your/maven/project"
./scripts/maven-performance-benchmark.sh
```

### Custom Configurations

Edit `scripts/benchmark-config.sh`:

```bash
# Add custom test configuration
declare -A CUSTOM_TEST_CONFIGS=(
    ["maven4-current_256m"]="maven4-current 256 false"
    ["maven4-current_768m"]="maven4-current 768 false"
)
```

### Memory Analysis

#### View Memory Usage Over Time
```bash
cat results/logs/maven4-current_512m_memory.csv
```

#### Analyze GC Behavior
```bash
cat results/logs/maven4-current_512m_gc.log
```

#### Build Logs
```bash
cat results/logs/maven4-current_512m.log
```

### CI/CD Integration

#### GitHub Actions
```yaml
name: Maven Performance Test
on: [push, pull_request]
jobs:
  benchmark:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          java-version: '21'
      - name: Run Maven Bench
        run: |
          git clone https://github.com/gnodet/maven-bench.git
          cd maven-bench
          ./scripts/run-benchmark.sh --quick
      - name: Upload Results
        uses: actions/upload-artifact@v3
        with:
          name: benchmark-results
          path: maven-bench/results/
```

#### Jenkins Pipeline
```groovy
pipeline {
    agent any
    stages {
        stage('Benchmark') {
            steps {
                sh '''
                    git clone https://github.com/gnodet/maven-bench.git
                    cd maven-bench
                    ./scripts/run-benchmark.sh --quick
                '''
                archiveArtifacts 'maven-bench/results/*'
            }
        }
    }
}
```

## Troubleshooting

### Common Issues

#### Maven Not Found
```bash
# Check PATH
echo $PATH

# Verify Maven installation
which mvn
mvn --version
```

#### Java Version Issues
```bash
# Check Java version
java -version

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
```

#### Memory Issues
```bash
# Check available memory
free -h

# Increase swap space
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

#### Permission Issues
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Check file permissions
ls -la scripts/
```

### Debug Mode

Enable verbose logging:
```bash
export MAVEN_BENCH_DEBUG=true
./scripts/run-benchmark.sh --quick
```

### Getting Help

1. **Check logs** in `results/logs/`
2. **Run environment check** with `--check`
3. **Enable debug mode** for verbose output
4. **Open GitHub issue** with logs and system info

## Performance Tips

### System Optimization
- Use SSD storage for faster I/O
- Ensure adequate RAM (4GB+ recommended)
- Close unnecessary applications during benchmarking
- Use dedicated test environment for consistent results

### Maven Optimization
- Use local repository on fast storage
- Configure parallel builds appropriately
- Tune JVM garbage collection settings
- Use Maven daemon for repeated builds
