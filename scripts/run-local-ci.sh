#!/bin/bash
# Local CI-equivalent script for development workflow
# Runs the same checks as GitHub Actions CI pipeline (see .github/workflows/ci.yml)

set -euo pipefail

echo "🚀 Running local CI checks..."
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" -eq 0 ]; then
        echo -e "${GREEN}✅ $message${NC}"
    else
        echo -e "${RED}❌ $message${NC}"
        return 1
    fi
}

echo "📋 Step 1: Guardrails Compliance Check"
if uv run python -m install_arch.cli enforce-guardrails; then
    print_status 0 "Guardrails check passed"
else
    print_status 1 "Guardrails check failed"
    exit 1
fi

echo
echo "🧪 Step 2: Running Tests with Coverage"
if uv run pytest tests/ -v --cov=src/install_arch --cov-report=term-missing --cov-report=xml; then
    print_status 0 "Tests passed"
else
    print_status 1 "Tests failed"
    exit 1
fi

echo
echo "🔍 Step 3: Code Quality Checks"

echo "  - Running ruff..."
if uv run ruff check src/ tests/; then
    print_status 0 "ruff passed"
else
    print_status 1 "ruff failed"
    exit 1
fi

echo "  - Running mypy..."
if uv run mypy src/install_arch/; then
    print_status 0 "mypy passed"
else
    print_status 1 "mypy failed"
    exit 1
fi

echo "  - Running ruff format check..."
if uv run ruff format --check src/ tests/; then
    print_status 0 "ruff format check passed"
else
    print_status 1 "ruff format check failed"
    exit 1
fi

echo
echo -e "${GREEN}🎉 All local CI checks passed! Ready to commit and push.${NC}"
echo
echo "💡 Tips:"
echo "  - Prefer: uv run python -m install_arch.cli local-ci"
echo "  - Run 'pre-commit run --all-files' to check everything locally"
echo "  - Use 'uv run pytest tests/' for quick test runs during development"
echo "  - Run this script again before pushing to ensure CI will pass"
