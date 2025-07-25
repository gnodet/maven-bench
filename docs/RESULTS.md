# Understanding Results

This guide explains how to interpret Maven Bench results and use them for performance analysis.

## Output Files

Maven Bench generates several types of output files in the `results/` directory:

### 1. Performance Matrix (`performance_matrix.txt`)

Human-readable table showing all test results:

```
======================================================================
                    MAVEN PERFORMANCE BENCHMARK RESULTS
======================================================================

Configuration                            Memory Req.  Exec. Time   Peak Mem.    Status  
------------------------------------------------------------------------------
maven3_1536m                            -Xmx1536m    4:23         1456MB       ✓     
maven4-rc4_1024m                        -Xmx1024m    TIMEOUT      N/A          ⏰     
maven4-rc4_1536m                        -Xmx1536m    3:45         1398MB       ✓     
maven4-rc4_1536m_maven3personality      -Xmx1536m    2:15         1245MB       ✓     
maven4-current_512m                     -Xmx512m     1:45         487MB        ✓     
maven4-current_512m_maven3personality   -Xmx512m     1:32         456MB        ✓     
```

### 2. CSV Data (`performance_results.csv`)

Machine-readable data for analysis:

```csv
Configuration,Maven Version,Memory (MB),Maven3 Personality,Execution Time,Peak Memory,Status
maven3_1536m,maven3,1536,false,4:23,1456MB,SUCCESS
maven4-rc4_1024m,maven4-rc4,1024,false,TIMEOUT,N/A,TIMEOUT
maven4-rc4_1536m,maven4-rc4,1536,false,3:45,1398MB,SUCCESS
maven4-current_512m,maven4-current,512,false,1:45,487MB,SUCCESS
```

### 3. Markdown Summary (`performance_summary.md`)

Ready-to-use markdown for documentation:

```markdown
| Configuration | Memory Requirement | Execution Time | Peak Memory | Status | Notes |
|---------------|-------------------|----------------|-------------|---------|-------|
| maven4-current | -Xmx512m | 1:45 | 487MB | ✅ Success |  |
| maven4-current + maven3Personality | -Xmx512m | 1:32 | 456MB | ✅ Success |  |
```

## Status Indicators

### Success Indicators
- **✓** - Build completed successfully
- **✅ Success** - Build completed successfully (markdown)

### Failure Indicators
- **✗** - Build failed (non-memory related)
- **💥** - Out of Memory Error
- **⏰** - Timeout (exceeded time limit)
- **❌ Failed** - Build failed (markdown)
- **❌ OOM** - Out of Memory Error (markdown)

## Metrics Explained

### Execution Time
- **Format**: `MM:SS` (minutes:seconds)
- **Measurement**: Total time for `mvn clean install`
- **Includes**: Compilation, testing, packaging
- **Excludes**: Environment setup, cleanup

**Example Analysis**:
```
maven3_1536m: 4:23
maven4-current_512m: 1:45
```
→ 61% faster execution with Maven 4 cache improvements

### Peak Memory Usage
- **Metric**: RSS (Resident Set Size) in MB
- **Measurement**: Maximum physical memory used during build
- **Sampling**: Every 5 seconds during execution
- **Accuracy**: ±5MB due to sampling interval

**Example Analysis**:
```
maven3_1536m: Peak 1456MB (95% of allocated 1536MB)
maven4-current_512m: Peak 487MB (95% of allocated 512MB)
```
→ 67% reduction in memory usage

### Memory Requirement
- **Metric**: JVM heap size (-Xmx setting)
- **Purpose**: Minimum memory needed to avoid OOM
- **Configuration**: Both -Xmx and -Xms set to same value

**Example Analysis**:
```
maven3: Requires 1536MB minimum
maven4-current: Runs successfully with 512MB
```
→ 67% reduction in memory requirements

## Performance Analysis

### Memory Efficiency Analysis

#### Comparing Memory Usage
```bash
# Extract memory data
grep "Peak Memory" results/performance_matrix.txt

# Calculate memory reduction
echo "scale=2; (1456 - 487) / 1456 * 100" | bc
# Result: 66.55% memory reduction
```

#### Memory Scaling Analysis
```bash
# Compare memory usage vs allocation
Configuration          Allocated  Peak Used  Utilization
maven3_1536m           1536MB     1456MB     94.8%
maven4-current_512m    512MB      487MB      95.1%
```

### Performance Comparison

#### Execution Time Analysis
```bash
# Convert time to seconds for comparison
maven3_1536m: 4:23 = 263 seconds
maven4-current_512m: 1:45 = 105 seconds
# Improvement: 60% faster
```

#### Maven3 Personality Impact
```bash
maven4-current_512m: 1:45 (105 seconds)
maven4-current_512m_maven3personality: 1:32 (92 seconds)
# Improvement: 12% faster with maven3personality
```

### Failure Analysis

#### Out of Memory Failures
```
maven4-rc4_512m: 💥 OOM
```
**Analysis**: Maven 4.0.0-rc-4 cannot run with 512MB, needs more memory

#### Timeout Failures
```
maven4-rc4_1024m: ⏰ TIMEOUT
```
**Analysis**: Build exceeded 10-minute limit, likely due to memory pressure

## Comparative Analysis

### Version Comparison Matrix

| Metric | Maven 3 | Maven 4.0.0-rc-4 | Maven 4 Current | Improvement |
|--------|---------|-------------------|-----------------|-------------|
| Min Memory | 1536MB | 1024MB | 512MB | 67% reduction |
| Exec Time | 4:23 | 3:45 | 1:45 | 60% faster |
| Peak Memory | 1456MB | 1398MB | 487MB | 67% less |

### Configuration Impact Analysis

| Configuration | Memory | Time | Notes |
|---------------|--------|------|-------|
| Standard | 512MB | 1:45 | Baseline |
| + maven3personality | 512MB | 1:32 | 12% faster |
| + More memory | 1024MB | 1:24 | Minimal improvement |

## Trend Analysis

### Memory Scaling Trends
```
Memory Allocation vs Peak Usage:
512MB  → 487MB  (95% utilization)
1024MB → 1192MB (116% - some swap usage)
1536MB → 1456MB (95% utilization)
```

**Insight**: Maven 4 current maintains consistent ~95% memory utilization regardless of allocation.

### Performance Trends
```
Memory vs Execution Time:
512MB  → 1:45
1024MB → 1:24
1536MB → Similar to 1024MB
```

**Insight**: Performance plateaus after 1024MB, indicating memory is not the bottleneck.

## Statistical Analysis

### Performance Metrics
```bash
# Calculate statistics from CSV data
awk -F',' '
BEGIN { sum=0; count=0; min=999; max=0 }
NR>1 && $6=="SUCCESS" { 
    # Convert MM:SS to seconds
    split($5, time, ":")
    seconds = time[1]*60 + time[2]
    sum += seconds
    count++
    if (seconds < min) min = seconds
    if (seconds > max) max = seconds
}
END { 
    avg = sum/count
    printf "Average: %.1fs\nMin: %ds\nMax: %ds\n", avg, min, max
}' results/performance_results.csv
```

### Memory Statistics
```bash
# Extract peak memory values
grep -o '[0-9]\+MB' results/performance_matrix.txt | \
sed 's/MB//' | \
awk '{ sum+=$1; count++; if($1<min || min==0) min=$1; if($1>max) max=$1 }
END { printf "Avg: %.0fMB, Min: %dMB, Max: %dMB\n", sum/count, min, max }'
```

## Visualization

### Creating Charts

#### Memory Usage Chart (using gnuplot)
```bash
# Extract data for plotting
awk -F',' 'NR>1 && $6=="SUCCESS" { print $3, substr($5,1,length($5)-2) }' \
    results/performance_results.csv > memory_data.txt

# Generate plot
gnuplot << EOF
set terminal png
set output 'memory_usage.png'
set xlabel 'Memory Allocation (MB)'
set ylabel 'Peak Memory Usage (MB)'
plot 'memory_data.txt' with points title 'Memory Usage'
EOF
```

#### Performance Comparison
```bash
# Create comparison data
echo "Configuration,Time_Seconds" > perf_data.csv
awk -F',' 'NR>1 && $6=="SUCCESS" { 
    split($5, time, ":")
    seconds = time[1]*60 + time[2]
    print $1 "," seconds 
}' results/performance_results.csv >> perf_data.csv
```

## Regression Analysis

### Performance Regression Detection
```bash
# Compare with baseline results
baseline_time=263  # Maven 3 baseline in seconds
current_time=105   # Current result

improvement=$(echo "scale=2; ($baseline_time - $current_time) / $baseline_time * 100" | bc)
echo "Performance improvement: ${improvement}%"

# Alert if regression detected
if (( $(echo "$improvement < 50" | bc -l) )); then
    echo "WARNING: Performance regression detected!"
fi
```

### Memory Regression Detection
```bash
# Compare memory usage
baseline_memory=1456  # Maven 3 baseline in MB
current_memory=487    # Current result

reduction=$(echo "scale=2; ($baseline_memory - $current_memory) / $baseline_memory * 100" | bc)
echo "Memory reduction: ${reduction}%"

# Alert if memory usage increased
if (( $(echo "$reduction < 60" | bc -l) )); then
    echo "WARNING: Memory regression detected!"
fi
```

## Reporting

### Executive Summary Template
```markdown
## Performance Summary

### Key Metrics
- **Memory Efficiency**: 67% reduction (1536MB → 512MB)
- **Execution Speed**: 60% faster (4:23 → 1:45)
- **Reliability**: 100% success rate at 512MB

### Recommendations
1. Deploy Maven 4 with cache improvements
2. Use maven3personality for optimal performance
3. Reduce memory allocation to 512MB minimum
```

### Detailed Analysis Template
```markdown
## Detailed Performance Analysis

### Test Environment
- **Test Project**: 100 modules, 400 tests
- **JVM**: OpenJDK 21 with G1GC
- **Command**: `mvn clean install`

### Results by Configuration
[Insert performance matrix here]

### Key Findings
1. **Memory Scaling**: Linear vs exponential growth
2. **Performance**: Consistent across memory settings
3. **Compatibility**: Full backward compatibility maintained
```

## Troubleshooting Results

### Inconsistent Results
- **Cause**: System load, background processes
- **Solution**: Run multiple iterations, use dedicated test environment

### Missing Data
- **Cause**: Process monitoring failure
- **Solution**: Check system permissions, verify monitoring tools

### Unexpected Failures
- **Cause**: Environment issues, configuration problems
- **Solution**: Check logs in `results/logs/` directory
