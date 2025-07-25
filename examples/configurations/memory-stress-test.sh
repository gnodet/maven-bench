#!/bin/bash

# Memory Stress Test Configuration
# Tests Maven 4 current with various memory settings to find minimum requirements

# Override default test configurations
declare -A MEMORY_STRESS_CONFIGS=(
    ["maven4-current_256m"]="maven4-current 256 false"
    ["maven4-current_384m"]="maven4-current 384 false"
    ["maven4-current_512m"]="maven4-current 512 false"
    ["maven4-current_768m"]="maven4-current 768 false"
    ["maven4-current_1024m"]="maven4-current 1024 false"
    ["maven4-current_1536m"]="maven4-current 1536 false"
)

# Export for use by main script
export TEST_CONFIGS_OVERRIDE="MEMORY_STRESS_CONFIGS"

echo "Memory Stress Test Configuration Loaded"
echo "Testing Maven 4 current with memory settings: 256MB to 1536MB"
