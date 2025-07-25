# macOS Setup Guide

This guide explains how to set up Maven Bench on macOS, including resolving Bash compatibility issues.

## 🍎 **macOS Compatibility Issues**

### **Problem: Bash 3.2 vs Bash 4.0+**

macOS ships with Bash 3.2 (from 2006) due to licensing restrictions, but Maven Bench requires Bash 4.0+ for associative arrays (`declare -A`).

**Error you might see:**
```bash
line 22: declare -A: invalid option
```

## 🔧 **Solutions**

### **Option 1: Install Modern Bash (Recommended)**

#### **Using Homebrew**
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install modern Bash
brew install bash

# Verify installation
/opt/homebrew/bin/bash --version  # Apple Silicon
# or
/usr/local/bin/bash --version     # Intel Mac
```

#### **Using MacPorts**
```bash
# Install MacPorts from https://www.macports.org/install.php

# Install Bash
sudo port install bash

# Verify installation
/opt/local/bin/bash --version
```

### **Option 2: Run with Explicit Bash**

If you have modern Bash installed, run scripts explicitly:

```bash
# Using Homebrew Bash (Apple Silicon)
/opt/homebrew/bin/bash scripts/run-benchmark.sh --check

# Using Homebrew Bash (Intel)
/usr/local/bin/bash scripts/run-benchmark.sh --check

# Using MacPorts Bash
/opt/local/bin/bash scripts/run-benchmark.sh --check
```

### **Option 3: Update Default Shell (Optional)**

```bash
# Add new Bash to allowed shells
echo "/opt/homebrew/bin/bash" | sudo tee -a /etc/shells

# Change default shell (optional)
chsh -s /opt/homebrew/bin/bash

# Verify
echo $BASH_VERSION
```

## 🚀 **Complete macOS Setup**

### **1. Install Prerequisites**

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install bash openjdk@21 maven bc
```

### **2. Configure Java**

```bash
# Set JAVA_HOME
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home

# Add to your shell profile (~/.zshrc or ~/.bash_profile)
echo 'export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home' >> ~/.zshrc
echo 'export PATH="$JAVA_HOME/bin:$PATH"' >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

### **3. Clone and Setup Maven Bench**

```bash
# Clone repository
git clone https://github.com/gnodet/maven-bench.git
cd maven-bench

# Make scripts executable
chmod +x scripts/*.sh tests/*.sh

# Test with modern Bash
/opt/homebrew/bin/bash scripts/run-benchmark.sh --check
```

### **4. Configure for macOS**

Edit `scripts/benchmark-config.sh` for macOS paths:

```bash
# Maven installations (adjust paths as needed)
export MAVEN3_PATH="/opt/homebrew/bin/mvn"
export MAVEN4_RC4_PATH="/opt/maven/bin/mvn"  # If you have Maven 4 installed
export MAVEN4_CURRENT_PATH="/path/to/maven4/bin/mvn"

# Java installation (Homebrew)
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
```

## 🧪 **Testing Your Setup**

### **1. Verify Bash Version**
```bash
/opt/homebrew/bin/bash --version
# Should show: GNU bash, version 5.x.x or later
```

### **2. Test Scripts**
```bash
# Run with modern Bash
/opt/homebrew/bin/bash scripts/run-benchmark.sh --check

# Should show Maven installations and Java version
```

### **3. Run Test Suite**
```bash
/opt/homebrew/bin/bash tests/test-benchmark.sh
# Should pass all tests
```

## 🔧 **Troubleshooting**

### **Issue: Command not found**
```bash
# Error: bash: /opt/homebrew/bin/bash: No such file or directory

# Solution: Check your architecture
arch
# If "i386" (Intel): use /usr/local/bin/bash
# If "arm64" (Apple Silicon): use /opt/homebrew/bin/bash
```

### **Issue: Java not found**
```bash
# Error: JAVA_HOME not found

# Solution: Install and configure Java
brew install openjdk@21
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
```

### **Issue: Maven not found**
```bash
# Error: Maven not found

# Solution: Install Maven
brew install maven

# Verify
which mvn
mvn --version
```

### **Issue: Permission denied**
```bash
# Error: Permission denied

# Solution: Make scripts executable
chmod +x scripts/*.sh tests/*.sh
```

## 📝 **Shell Profile Configuration**

Add to your `~/.zshrc` (or `~/.bash_profile` if using Bash):

```bash
# Maven Bench Configuration for macOS
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

# Alias for modern Bash (optional)
alias bash5="/opt/homebrew/bin/bash"
alias maven-bench="cd ~/maven-bench && /opt/homebrew/bin/bash"

# Function to run Maven Bench with correct Bash
maven-bench-run() {
    cd ~/maven-bench
    /opt/homebrew/bin/bash scripts/run-benchmark.sh "$@"
}
```

## 🚀 **Quick Start Commands**

Once setup is complete:

```bash
# Environment check
/opt/homebrew/bin/bash scripts/run-benchmark.sh --check

# Quick demo
/opt/homebrew/bin/bash scripts/run-benchmark.sh --quick

# Interactive demo
/opt/homebrew/bin/bash scripts/demo-benchmark.sh

# Full test suite
/opt/homebrew/bin/bash scripts/run-benchmark.sh --full
```

## 📱 **Alternative: Use Docker**

If you prefer not to install Bash 4+:

```bash
# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    bash bc maven openjdk-21-jdk git
WORKDIR /maven-bench
EOF

# Build and run
docker build -t maven-bench .
docker run -it -v $(pwd):/maven-bench maven-bench bash
./scripts/run-benchmark.sh --check
```

## 🎯 **Summary**

1. **Install modern Bash** with Homebrew: `brew install bash`
2. **Configure Java** with OpenJDK 21: `brew install openjdk@21`
3. **Run scripts explicitly** with modern Bash: `/opt/homebrew/bin/bash scripts/run-benchmark.sh`
4. **Update shell profile** for convenience

The key is using Bash 4.0+ instead of the system's Bash 3.2. Once configured, Maven Bench works perfectly on macOS!
