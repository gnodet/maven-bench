#!/bin/bash

# Version Comparison Configuration
# Compares performance across Maven versions with equivalent memory settings

# Override default test configurations
declare -A VERSION_COMPARISON_CONFIGS=(
    ["maven3_1536m_baseline"]="maven3 1536 false"
    ["maven4-rc4_1536m_baseline"]="maven4-rc4 1536 false"
    ["maven4-rc4_1536m_optimized"]="maven4-rc4 1536 true"
    ["maven4-current_1536m_baseline"]="maven4-current 1536 false"
    ["maven4-current_1536m_optimized"]="maven4-current 1536 true"
    ["maven4-current_512m_efficient"]="maven4-current 512 true"
)

# Export for use by main script
export TEST_CONFIGS_OVERRIDE="VERSION_COMPARISON_CONFIGS"

echo "Version Comparison Configuration Loaded"
echo "Testing Maven 3, Maven 4.0.0-rc-4, and Maven 4 current"
