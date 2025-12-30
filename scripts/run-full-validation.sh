#!/bin/bash
# run-full-validation.sh
# Execute all validation tests in sequence

set -e

echo "=========================================="
echo "  KDE Plasma Installation Validation Suite"
echo "=========================================="

BASE_DIR="$(dirname "$0")"
LOG_FILE="/tmp/kde-validation-$(date +%Y%m%d-%H%M%S).log"

echo "Logging to: $LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# Test execution order
TESTS=(
    "validate-package-installation.sh"
    "validate-services.sh"
    "validate-security.sh"
    "validate-hardware.sh"
)

# Run installation-time tests first
echo "Running installation-time validation tests..."
for test in "${TESTS[@]}"; do
    if [ -f "$BASE_DIR/$test" ]; then
        echo "Executing $test..."
        if bash "$BASE_DIR/$test"; then
            echo "✓ $test PASSED"
        else
            echo "✗ $test FAILED"
            exit 1
        fi
    else
        echo "WARNING: $test not found, skipping"
    fi
done

# Post-install tests (require GUI environment)
if [ -n "$DISPLAY" ] && [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]]; then
    echo "Running post-install GUI validation tests..."
    POST_GUI_TESTS=(
        "validate-kde-desktop.sh"
        "validate-applications.sh"
    )

    for test in "${POST_GUI_TESTS[@]}"; do
        if [ -f "$BASE_DIR/$test" ]; then
            echo "Executing $test..."
            if bash "$BASE_DIR/$test"; then
                echo "✓ $test PASSED"
            else
                echo "✗ $test FAILED"
                exit 1
            fi
        else
            echo "WARNING: $test not found, skipping"
        fi
    done
else
    echo "WARNING: Not in KDE GUI environment, skipping GUI tests"
    echo "Current desktop: $XDG_CURRENT_DESKTOP"
    echo "DISPLAY: $DISPLAY"
fi

echo ""
echo "=========================================="
echo "  ALL VALIDATION TESTS COMPLETED SUCCESSFULLY"
echo "=========================================="
echo "Log file: $LOG_FILE"