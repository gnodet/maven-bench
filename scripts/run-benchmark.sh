#!/bin/bash

# Maven Performance Benchmark Runner
# Simple wrapper script for running benchmarks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/benchmark-config.sh"

# Default action
ACTION="help"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --quick)
            ACTION="quick"
            shift
            ;;
        --full)
            ACTION="full"
            shift
            ;;
        --check)
            ACTION="check"
            shift
            ;;
        --help|-h)
            ACTION="help"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            ACTION="help"
            shift
            ;;
    esac
done

case "${ACTION}" in
    "check")
        echo "=== Maven Performance Benchmark - Environment Check ==="
        echo ""
        check_environment
        echo ""
        echo "To run benchmarks:"
        echo "  ./run-benchmark.sh --quick   # Quick test (3 configurations)"
        echo "  ./run-benchmark.sh --full    # Full test (11 configurations)"
        ;;
        
    "quick")
        echo "=== Maven Performance Benchmark - Quick Test ==="
        echo ""
        echo "Running quick benchmark with cache-optimized Maven 4 configurations..."
        echo "This will test 3 configurations and should complete in 10-15 minutes."
        echo ""
        
        # Override test configurations for quick test
        export TEST_CONFIGS_OVERRIDE="QUICK_TEST_CONFIGS"
        
        "${SCRIPT_DIR}/maven-performance-benchmark.sh"
        ;;
        
    "full")
        echo "=== Maven Performance Benchmark - Full Test Suite ==="
        echo ""
        echo "Running full benchmark with all Maven configurations..."
        echo "This will test 11 configurations and may take 1-2 hours."
        echo ""
        
        read -p "Are you sure you want to run the full test suite? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Override test configurations for full test
            export TEST_CONFIGS_OVERRIDE="FULL_TEST_CONFIGS"
            
            "${SCRIPT_DIR}/maven-performance-benchmark.sh"
        else
            echo "Full test cancelled."
            echo "Use './run-benchmark.sh --quick' for a faster test."
        fi
        ;;
        
    "help"|*)
        print_usage
        echo ""
        echo "Quick Start:"
        echo "1. Check your environment:"
        echo "   ./run-benchmark.sh --check"
        echo ""
        echo "2. Run a quick test:"
        echo "   ./run-benchmark.sh --quick"
        echo ""
        echo "3. View results:"
        echo "   cat maven-benchmark/results/performance_matrix.txt"
        ;;
esac
