# Maven Bench

A comprehensive performance benchmarking tool for Apache Maven with focus on memory efficiency, build times, and cache optimizations.

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Java](https://img.shields.io/badge/Java-21+-orange.svg)](https://openjdk.java.net/)
[![Maven](https://img.shields.io/badge/Maven-3.x%20%7C%204.x-green.svg)](https://maven.apache.org/)

## 🎯 Purpose

Maven Bench provides automated performance testing for different Maven configurations, specifically designed to:

- **Validate performance improvements** in Maven core and plugins
- **Measure memory efficiency** and identify memory scaling issues
- **Compare build times** across Maven versions and configurations
- **Monitor cache effectiveness** and object creation patterns
- **Support CI/CD integration** for continuous performance monitoring

## 🚀 Quick Start

### Prerequisites

- Java 21+
- Maven 3.x and/or Maven 4.x installations
- Linux/macOS environment (Windows support via WSL)
- At least 2GB RAM for testing

### Installation

```bash
git clone https://github.com/gnodet/maven-bench.git
cd maven-bench
chmod +x scripts/*.sh
```

### Environment Check

```bash
./scripts/run-benchmark.sh --check
```

### Quick Demo

```bash
# Run a quick 3-configuration test (~5 minutes)
./scripts/run-benchmark.sh --quick

# View results
cat results/performance_matrix.txt
```

## 📊 Features

### Core Capabilities
- ✅ **Multi-version Maven support** (3.x, 4.x)
- ✅ **Memory usage monitoring** with peak memory tracking
- ✅ **Build time measurement** with timeout handling
- ✅ **Automated test project generation** (configurable size)
- ✅ **Multiple output formats** (text, CSV, markdown)
- ✅ **Detailed logging** (build logs, GC logs, memory traces)

### Test Scenarios
- ✅ **Memory scaling tests** (512MB to 2GB+)
- ✅ **Maven3 personality mode** performance comparison
- ✅ **Cache effectiveness** validation
- ✅ **Large multi-module projects** (100+ modules)
- ✅ **Dependency chain stress testing**

### Output Formats
- 📊 **Performance Matrix** - Human-readable results table
- 📈 **CSV Data** - Machine-readable for analysis
- 📝 **Markdown Summary** - Ready for GitHub/documentation
- 🔍 **Detailed Logs** - For debugging and deep analysis

## 🎪 Usage

### Interactive Demo
```bash
./scripts/demo-benchmark.sh
```

### Command Line Options
```bash
# Environment validation
./scripts/run-benchmark.sh --check

# Quick test (3 configurations, ~5 minutes)
./scripts/run-benchmark.sh --quick

# Full test suite (11 configurations, ~1-2 hours)
./scripts/run-benchmark.sh --full

# Custom configuration
./scripts/maven-performance-benchmark.sh
```

### Configuration
Edit `scripts/benchmark-config.sh` to customize:
- Maven installation paths
- Memory test ranges
- Test project parameters
- Timeout settings

## 📈 Sample Results

```
Configuration                            Memory Req.  Exec. Time   Peak Mem.    Status  
------------------------------------------------------------------------------
maven3_1536m                            -Xmx1536m    4:23         1456MB       ✓     
maven4-rc4_1024m                        -Xmx1024m    TIMEOUT      N/A          ⏰     
maven4-rc4_1536m                        -Xmx1536m    3:45         1398MB       ✓     
maven4-current_512m                     -Xmx512m     1:45         487MB        ✓     
maven4-current_512m_maven3personality   -Xmx512m     1:32         456MB        ✓     
```

**Key Findings:**
- 🎯 **67% memory reduction** with cache improvements
- ⚡ **Faster execution** with maven3personality mode
- 🔄 **Linear memory scaling** vs exponential growth

## 📁 Repository Structure

```
maven-bench/
├── scripts/                      # Benchmark scripts
│   ├── maven-performance-benchmark.sh  # Main benchmark engine
│   ├── run-benchmark.sh               # Simple wrapper
│   ├── demo-benchmark.sh              # Interactive demo
│   ├── create-test-project.sh         # Test project generator
│   └── benchmark-config.sh            # Configuration
├── docs/                         # Documentation
│   ├── USAGE.md                 # Detailed usage guide
│   ├── CONFIGURATION.md         # Configuration reference
│   ├── RESULTS.md               # Understanding results
│   └── CONTRIBUTING.md          # Contribution guidelines
├── examples/                     # Example configurations and results
├── tests/                        # Test scripts
└── .github/                      # GitHub workflows and templates
```

## 🔧 Advanced Usage

### Custom Test Projects
```bash
# Create custom test project
./scripts/create-test-project.sh --modules 50 --depth 3

# Use existing project
export TEST_PROJECT_DIR="/path/to/your/maven/project"
./scripts/maven-performance-benchmark.sh
```

### CI/CD Integration
```yaml
- name: Maven Performance Benchmark
  run: |
    git clone https://github.com/gnodet/maven-bench.git
    cd maven-bench
    ./scripts/run-benchmark.sh --quick
    cat results/performance_results.csv
```

### Memory Analysis
```bash
# View memory usage over time
cat results/logs/*_memory.csv

# Analyze GC behavior
cat results/logs/*_gc.log
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

### Areas for Contribution
- Additional Maven version support
- Windows compatibility improvements
- New test scenarios and configurations
- Performance analysis tools
- Documentation improvements

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Projects

- [Apache Maven](https://maven.apache.org/) - The build tool being benchmarked
- [Maven Performance Improvements](https://github.com/apache/maven/pulls) - Related performance PRs
- [Maven Turbo Reactor](https://github.com/maven-turbo-reactor) - Maven performance tools

## 📞 Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/gnodet/maven-bench/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/gnodet/maven-bench/discussions)
- 📧 **Email**: For security issues only

---

**Note**: This tool is designed for performance analysis and benchmarking. Results may vary based on hardware, JVM version, and system configuration.
