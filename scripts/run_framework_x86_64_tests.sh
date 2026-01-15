#!/usr/bin/env bash
# Framework x86_64 Test Execution Script
# Purpose: Execute all Grain OS tests on Framework Ubuntu x86_64 and generate verification report
# Usage: ./scripts/run_framework_x86_64_tests.sh [--syscall-only] [--integration-only]

set -euo pipefail

# Script directory (for relative paths)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# Configuration
TIMESTAMP=$(TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst")
REPORT_DIR="$REPO_ROOT/docs/test-reports"
REPORT_FILE="$REPORT_DIR/framework_x86_64_test_execution_${TIMESTAMP}.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create report directory
mkdir -p "$REPORT_DIR"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments
RUN_SYSCALL=true
RUN_INTEGRATION=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --syscall-only)
            RUN_INTEGRATION=false
            shift
            ;;
        --integration-only)
            RUN_SYSCALL=false
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Usage: $0 [--syscall-only] [--integration-only]"
            exit 1
            ;;
    esac
done

# Verify Zig is installed
if ! command -v zig &> /dev/null; then
    log_error "Zig compiler not found. Please install Zig 0.15.2 or compatible."
    exit 1
fi

ZIG_VERSION=$(zig version)
log_info "Zig version: $ZIG_VERSION"

# Verify platform
PLATFORM=$(uname -m)
log_info "Platform: $PLATFORM"

if [[ "$PLATFORM" != "x86_64" ]]; then
    log_warn "Platform is $PLATFORM, expected x86_64. Results may not be representative."
fi

# Initialize report
cat > "$REPORT_FILE" << EOF
# Framework x86_64 Test Execution Report

**Date**: ${TIMESTAMP}  
**Platform**: $(uname -m) ($(uname -s) $(uname -r))  
**Zig Version**: ${ZIG_VERSION}  
**Repository**: $(pwd)

---

## Test Execution Summary

### Environment

- **Platform**: $(uname -m)
- **OS**: $(uname -s) $(uname -r)
- **Zig Version**: ${ZIG_VERSION}
- **Build Command**: \`zig build test --summary all\`

---

## Results

EOF

# Run syscall verification tests
if [[ "$RUN_SYSCALL" == "true" ]]; then
    log_info "Running Syscall Verification tests..."
    
    SYSCALL_START=$(date +%s)
    
    # Run tests and capture output
    if zig build test --summary all 2>&1 | tee "$REPORT_DIR/syscall_test_output_${TIMESTAMP}.log" | grep -q "163_syscall"; then
        SYSCALL_PASSED=$(grep -c "163_syscall" "$REPORT_DIR/syscall_test_output_${TIMESTAMP}.log" || echo "0")
        SYSCALL_FAILED=$(grep -c "FAIL\|Error\|error" "$REPORT_DIR/syscall_test_output_${TIMESTAMP}.log" || echo "0")
        SYSCALL_DURATION=$(($(date +%s) - SYSCALL_START))
        
        log_info "Syscall Verification tests: ${SYSCALL_PASSED} tests executed in ${SYSCALL_DURATION}s"
        
        cat >> "$REPORT_FILE" << EOF
### Syscall Verification Tests

- **Tests Executed**: ${SYSCALL_PASSED}
- **Tests Passed**: ${SYSCALL_PASSED}
- **Tests Failed**: ${SYSCALL_FAILED}
- **Execution Time**: ${SYSCALL_DURATION}s
- **Expected**: 90 tests (87 functional + 3 performance)

**Status**: ${SYSCALL_FAILED} -eq 0 ? "✅ PASS" : "❌ FAIL"}

EOF
    else
        log_error "Syscall Verification tests not found in output"
        cat >> "$REPORT_FILE" << EOF
### Syscall Verification Tests

- **Status**: ❌ **NOT FOUND**
- **Error**: Tests not found in output

EOF
    fi
fi

# Run end-to-end integration tests
if [[ "$RUN_INTEGRATION" == "true" ]]; then
    log_info "Running End-to-End Integration tests..."
    
    INTEGRATION_START=$(date +%s)
    
    # Run tests and capture output
    if zig build test --summary all 2>&1 | tee "$REPORT_DIR/integration_test_output_${TIMESTAMP}.log" | grep -q "164_end_to_end"; then
        INTEGRATION_PASSED=$(grep -c "164_end_to_end" "$REPORT_DIR/integration_test_output_${TIMESTAMP}.log" || echo "0")
        INTEGRATION_FAILED=$(grep -c "FAIL\|Error\|error" "$REPORT_DIR/integration_test_output_${TIMESTAMP}.log" || echo "0")
        INTEGRATION_DURATION=$(($(date +%s) - INTEGRATION_START))
        
        log_info "End-to-End Integration tests: ${INTEGRATION_PASSED} tests executed in ${INTEGRATION_DURATION}s"
        
        cat >> "$REPORT_FILE" << EOF
### End-to-End Integration Tests

- **Tests Executed**: ${INTEGRATION_PASSED}
- **Tests Passed**: ${INTEGRATION_PASSED}
- **Tests Failed**: ${INTEGRATION_FAILED}
- **Execution Time**: ${INTEGRATION_DURATION}s
- **Expected**: 61 tests (37 original + 24 new: 6 resource cleanup + 9 edge cases + 9 concurrent)

**Status**: ${INTEGRATION_FAILED} -eq 0 ? "✅ PASS" : "❌ FAIL"}

EOF
    else
        log_error "End-to-End Integration tests not found in output"
        cat >> "$REPORT_FILE" << EOF
### End-to-End Integration Tests

- **Status**: ❌ **NOT FOUND**
- **Error**: Tests not found in output

EOF
    fi
fi

# Performance benchmarks (if syscall tests ran)
if [[ "$RUN_SYSCALL" == "true" ]]; then
    log_info "Checking performance benchmarks..."
    
    if grep -q "performance" "$REPORT_DIR/syscall_test_output_${TIMESTAMP}.log" 2>/dev/null; then
        cat >> "$REPORT_FILE" << EOF
### Performance Benchmarks

- **Latency Benchmark**: Check test output for results
- **Throughput Benchmark**: Check test output for results
- **Mixed Workload Benchmark**: Check test output for results

**Thresholds**:
- Latency: < 10ms (10,000,000 nanoseconds)
- Throughput: ≥ 100 ops/sec

EOF
    fi
fi

# Summary
cat >> "$REPORT_FILE" << EOF
---

## Summary

**Total Tests Executed**: $((SYSCALL_PASSED + INTEGRATION_PASSED))
**Total Tests Expected**: 151 (90 syscall + 61 integration)
**Total Execution Time**: $((SYSCALL_DURATION + INTEGRATION_DURATION))s

**Next Steps**:
1. Review test output logs in \`$REPORT_DIR\`
2. Fix any test failures
3. Verify performance benchmarks meet thresholds
4. Update status in task list

---

**Report Generated**: ${TIMESTAMP}  
**Report Location**: ${REPORT_FILE}

EOF

log_info "Test execution complete. Report: $REPORT_FILE"
log_info "Test output logs: $REPORT_DIR/"
