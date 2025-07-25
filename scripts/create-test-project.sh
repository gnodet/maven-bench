#!/bin/bash

# Create a simpler test project for Maven benchmarking
# This creates a more manageable project that will actually build successfully

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_PROJECT_DIR="${SCRIPT_DIR}/../maven-benchmark/simple-test-project"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

create_simple_project() {
    log "Creating simple test project..."
    
    # Remove existing project
    rm -rf "${TEST_PROJECT_DIR}"
    mkdir -p "${TEST_PROJECT_DIR}"
    
    cd "${TEST_PROJECT_DIR}"
    
    # Create parent POM
    cat > pom.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <groupId>org.apache.maven.benchmark</groupId>
    <artifactId>maven-benchmark-parent</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>pom</packaging>
    
    <name>Maven Benchmark Test Project</name>
    <description>Test project for Maven performance benchmarking</description>
    
    <properties>
        <maven.compiler.source>21</maven.compiler.source>
        <maven.compiler.target>21</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <junit.version>5.10.0</junit.version>
    </properties>
    
    <modules>
EOF

    # Create 100 modules with dependencies
    for i in {1..100}; do
        echo "        <module>module-${i}</module>" >> pom.xml
    done
    
    cat >> pom.xml << 'EOF'
    </modules>
    
    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.junit.jupiter</groupId>
                <artifactId>junit-jupiter</artifactId>
                <version>${junit.version}</version>
                <scope>test</scope>
            </dependency>
        </dependencies>
    </dependencyManagement>
    
    <build>
        <pluginManagement>
            <plugins>
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-compiler-plugin</artifactId>
                    <version>3.11.0</version>
                </plugin>
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-surefire-plugin</artifactId>
                    <version>3.1.2</version>
                </plugin>
            </plugins>
        </pluginManagement>
    </build>
</project>
EOF

    # Create modules
    for i in {1..100}; do
        local module_dir="module-${i}"
        mkdir -p "${module_dir}/src/main/java/org/apache/maven/benchmark/module${i}"
        mkdir -p "${module_dir}/src/test/java/org/apache/maven/benchmark/module${i}"
        
        # Create module POM
        cat > "${module_dir}/pom.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.apache.maven.benchmark</groupId>
        <artifactId>maven-benchmark-parent</artifactId>
        <version>1.0.0-SNAPSHOT</version>
    </parent>
    
    <artifactId>module-${i}</artifactId>
    <name>Module ${i}</name>
    
    <dependencies>
EOF

        # Add dependencies to previous modules (creates a dependency chain)
        if [[ $i -gt 1 ]]; then
            local dep_count=$((i > 5 ? 5 : i-1))  # Limit to 5 dependencies max
            for ((j=1; j<=dep_count; j++)); do
                local dep_module=$((i - j))
                cat >> "${module_dir}/pom.xml" << EOF
        <dependency>
            <groupId>org.apache.maven.benchmark</groupId>
            <artifactId>module-${dep_module}</artifactId>
            <version>\${project.version}</version>
        </dependency>
EOF
            done
        fi
        
        cat >> "${module_dir}/pom.xml" << 'EOF'
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
EOF

        # Create Java class
        cat > "${module_dir}/src/main/java/org/apache/maven/benchmark/module${i}/Module${i}.java" << EOF
package org.apache.maven.benchmark.module${i};

$(if [[ $i -gt 1 ]]; then
    for ((j=1; j<=5 && j<i; j++)); do
        local dep_module=$((i - j))
        echo "import org.apache.maven.benchmark.module${dep_module}.Module${dep_module};"
    done
fi)

/**
 * Module ${i} for Maven benchmark testing.
 * This class demonstrates typical enterprise Java patterns.
 */
public class Module${i} {
    
    private final String name = "Module${i}";
    private final int id = ${i};
    
    public String getName() {
        return name;
    }
    
    public int getId() {
        return id;
    }
    
    public String getInfo() {
        StringBuilder info = new StringBuilder();
        info.append("Module ").append(id).append(": ").append(name);
        
$(if [[ $i -gt 1 ]]; then
    for ((j=1; j<=3 && j<i; j++)); do
        local dep_module=$((i - j))
        echo "        info.append(\", depends on: \").append(new Module${dep_module}().getName());"
    done
fi)
        
        return info.toString();
    }
    
    public void doWork() {
        // Simulate some work
        for (int i = 0; i < 1000; i++) {
            Math.sqrt(i * id);
        }
    }
}
EOF

        # Create test class
        cat > "${module_dir}/src/test/java/org/apache/maven/benchmark/module${i}/Module${i}Test.java" << EOF
package org.apache.maven.benchmark.module${i};

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Test for Module${i}.
 */
public class Module${i}Test {
    
    @Test
    public void testGetName() {
        Module${i} module = new Module${i}();
        assertEquals("Module${i}", module.getName());
    }
    
    @Test
    public void testGetId() {
        Module${i} module = new Module${i}();
        assertEquals(${i}, module.getId());
    }
    
    @Test
    public void testGetInfo() {
        Module${i} module = new Module${i}();
        String info = module.getInfo();
        assertNotNull(info);
        assertTrue(info.contains("Module ${i}"));
    }
    
    @Test
    public void testDoWork() {
        Module${i} module = new Module${i}();
        // Should not throw any exception
        assertDoesNotThrow(() -> module.doWork());
    }
}
EOF

        log "Created module ${i}/100"
    done
    
    success "Simple test project created with 100 modules"
    log "Project location: ${TEST_PROJECT_DIR}"
    log "Modules: 100"
    log "Dependencies: Chain pattern with max 5 deps per module"
    log "Classes: 100 main classes + 100 test classes"
    log "Tests: 400 unit tests total"
}

# Create .mvn directory with maven.config
create_maven_config() {
    mkdir -p "${TEST_PROJECT_DIR}/.mvn"
    
    # Create a simple maven.config that works with both Maven 3 and 4
    cat > "${TEST_PROJECT_DIR}/.mvn/maven.config" << 'EOF'
-Dmaven.artifact.threads=8
-Dmaven.compile.fork=true
EOF

    log "Created .mvn/maven.config"
}

main() {
    create_simple_project
    create_maven_config
    
    echo ""
    success "Simple test project ready for benchmarking!"
    echo ""
    echo "To test the project:"
    echo "  cd ${TEST_PROJECT_DIR}"
    echo "  mvn clean compile test"
    echo ""
    echo "To use with benchmark:"
    echo "  Update TEST_PROJECT_DIR in maven-performance-benchmark.sh"
    echo "  Or run: ./run-benchmark.sh --quick"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
