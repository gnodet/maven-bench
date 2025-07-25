#!/bin/bash

# Demo script for Maven Performance Benchmark
# Shows the performance improvements from PR #2506

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}================================================================${NC}"
    echo -e "${CYAN}           MAVEN PERFORMANCE BENCHMARK DEMO${NC}"
    echo -e "${CYAN}           PR #2506 Cache Improvements${NC}"
    echo -e "${CYAN}================================================================${NC}"
    echo ""
}

print_section() {
    echo -e "${BLUE}▶ $1${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

show_overview() {
    print_section "Overview"
    echo "This benchmark demonstrates the performance improvements from Maven cache"
    echo "optimizations in PR #2506. The improvements include:"
    echo ""
    echo "• 📈 Better memory efficiency (67% reduction)"
    echo "• ⚡ Faster build times with maven3personality mode"
    echo "• 🔄 Improved caching of Maven model objects"
    echo "• 🎯 Reduced memory scaling issues in large projects"
    echo ""
}

show_test_project() {
    print_section "Test Project Details"
    echo "The benchmark uses a generated multi-module project:"
    echo ""
    echo "• 📦 100 Maven modules with dependency chains"
    echo "• 🔗 Up to 5 dependencies per module"
    echo "• ☕ 200 Java classes (100 main + 100 test)"
    echo "• 🧪 400 unit tests total"
    echo "• 🏗️  Realistic enterprise project structure"
    echo ""
}

show_configurations() {
    print_section "Test Configurations"
    echo "The benchmark tests different Maven configurations:"
    echo ""
    echo "📊 Quick Test (3 configurations):"
    echo "   • maven4-current_512m"
    echo "   • maven4-current_512m_maven3personality"
    echo "   • maven4-current_1024m"
    echo ""
    echo "📊 Full Test (11 configurations):"
    echo "   • Maven 3: 1024MB, 1536MB"
    echo "   • Maven 4.0.0-rc-4: 512MB, 1024MB, 1536MB (±maven3personality)"
    echo "   • Maven 4 Current: 512MB, 1024MB, 1536MB, 2048MB (±maven3personality)"
    echo ""
}

run_environment_check() {
    print_section "Environment Check"
    echo "Checking Maven installations and environment..."
    echo ""
    
    if ./run-benchmark.sh --check; then
        print_success "Environment check passed"
    else
        print_error "Environment check failed"
        echo ""
        echo "Please ensure you have:"
        echo "• Maven 3 installed (sudo apt install maven)"
        echo "• Maven 4.0.0-rc-4 downloaded to /opt/maven"
        echo "• Maven 4 current built (mvn install -DskipTests -Drat.skip=true)"
        echo "• Java 21 installed"
        return 1
    fi
    echo ""
}

run_quick_demo() {
    print_section "Running Quick Demo"
    echo "This will run a quick benchmark with 3 configurations..."
    echo "Expected duration: ~5 minutes"
    echo ""
    
    read -p "Continue with quick demo? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Demo cancelled."
        return 0
    fi
    
    echo ""
    print_info "Starting quick benchmark..."
    
    if ./run-benchmark.sh --quick; then
        print_success "Quick benchmark completed successfully!"
        show_results
    else
        print_error "Quick benchmark failed"
        return 1
    fi
}

show_results() {
    print_section "Results Summary"
    
    if [[ -f "maven-benchmark/results/performance_matrix.txt" ]]; then
        echo "📊 Performance Matrix:"
        echo ""
        cat maven-benchmark/results/performance_matrix.txt
        echo ""
    fi
    
    if [[ -f "maven-benchmark/results/performance_summary.md" ]]; then
        print_info "Detailed results available in:"
        echo "   • maven-benchmark/results/performance_matrix.txt"
        echo "   • maven-benchmark/results/performance_results.csv"
        echo "   • maven-benchmark/results/performance_summary.md"
        echo ""
    fi
}

show_key_findings() {
    print_section "Key Findings from PR #2506"
    echo "The cache improvements demonstrate:"
    echo ""
    echo "🎯 Memory Efficiency:"
    echo "   • Maven 4 with cache improvements can build with 512MB"
    echo "   • Previous versions required 1536MB+ for similar projects"
    echo "   • 67% reduction in memory requirements"
    echo ""
    echo "⚡ Performance:"
    echo "   • Maven3 personality mode provides best execution times"
    echo "   • Consistent performance across different memory settings"
    echo "   • Reduced garbage collection pressure"
    echo ""
    echo "🔄 Scalability:"
    echo "   • Memory usage scales linearly instead of exponentially"
    echo "   • Cache hits reduce object creation overhead"
    echo "   • Better handling of large multi-module projects"
    echo ""
}

show_usage() {
    print_section "Usage Instructions"
    echo "To run benchmarks manually:"
    echo ""
    echo "🔍 Check environment:"
    echo "   ./run-benchmark.sh --check"
    echo ""
    echo "⚡ Quick test (3 configs, ~5 min):"
    echo "   ./run-benchmark.sh --quick"
    echo ""
    echo "📊 Full test (11 configs, ~1-2 hours):"
    echo "   ./run-benchmark.sh --full"
    echo ""
    echo "📁 View results:"
    echo "   cat maven-benchmark/results/performance_matrix.txt"
    echo ""
    echo "🔧 Customize configurations:"
    echo "   Edit benchmark-config.sh"
    echo ""
}

show_files() {
    print_section "Generated Files"
    echo "The benchmark creates the following structure:"
    echo ""
    echo "📁 maven-benchmark/"
    echo "   ├── 📁 simple-test-project/     # 100-module test project"
    echo "   ├── 📁 results/                 # Benchmark results"
    echo "   │   ├── 📄 performance_matrix.txt"
    echo "   │   ├── 📄 performance_results.csv"
    echo "   │   └── 📄 performance_summary.md"
    echo "   └── 📁 logs/                    # Detailed logs"
    echo "       ├── 📄 *.log               # Maven build logs"
    echo "       ├── 📄 *_gc.log            # GC logs"
    echo "       └── 📄 *_memory.csv        # Memory usage"
    echo ""
}

main() {
    print_header
    show_overview
    show_test_project
    show_configurations
    
    echo ""
    echo "Choose an option:"
    echo "1) Check environment"
    echo "2) Run quick demo"
    echo "3) Show usage instructions"
    echo "4) Show key findings"
    echo "5) Show generated files"
    echo "6) Exit"
    echo ""
    
    read -p "Enter choice (1-6): " choice
    echo ""
    
    case $choice in
        1)
            run_environment_check
            ;;
        2)
            run_environment_check && run_quick_demo
            ;;
        3)
            show_usage
            ;;
        4)
            show_key_findings
            ;;
        5)
            show_files
            ;;
        6)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
    
    echo ""
    echo "Demo completed. Run './demo-benchmark.sh' again to explore other options."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
