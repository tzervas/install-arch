#!/bin/bash
# Complete Dev Container automation sequence
# Runs all Dev Container operations in proper order

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print debug output
debug() {
    if [ "$DEBUG" = true ]; then
        echo -e "${BLUE}🐛 DEBUG: $1${NC}"
    fi
}

# Function to print colored output
print_header() {
    echo -e "\n${BLUE}🚀 $1${NC}"
    echo "═══════════════════════════════════════════════════════════════"
}

print_step() {
    echo -e "${YELLOW}📋 Step: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to wait for user confirmation
wait_for_user() {
    local message="${1:-Press Enter to continue...}"
    echo
    read -p "$message" -r
    echo
}

# Function to run a command and check its result
run_command() {
    local cmd="$1"
    local description="$2"

    print_step "$description"
    echo "Command: $cmd"

    if [ "$DEBUG" = true ]; then
        debug "Executing command: $cmd"
    fi

    if eval "$cmd"; then
        print_success "$description completed"
        return 0
    else
        print_error "$description failed"
        return 1
    fi
}

# Main automation sequence
main() {
    print_header "Dev Container Complete Automation Sequence (DEBUG MODE)"
    echo "This will run all Dev Container operations in sequence with debug output."
    echo "Make sure Docker is running and you have sufficient permissions."
    wait_for_user "Ready to start? (Press Enter to continue, Ctrl+C to abort)"

    cd "$PROJECT_ROOT"

    # Enable debug mode
    export DEBUG=true
    debug "Debug mode enabled"
    debug "Current directory: $(pwd)"
    debug "User: $(whoami)"
    debug "Docker version: $(docker --version 2>/dev/null || echo 'Docker not found')"

    # Step 1: Check current status
    print_header "Step 1: Checking Current Status"
    if ! run_command "./scripts/devcontainer.sh status" "Check Dev Container status"; then
        print_error "Status check failed, but continuing..."
    fi

    # Step 2: Clean up existing resources
    print_header "Step 2: Cleaning Up Resources"
    if ! run_command "./scripts/devcontainer.sh clean" "Clean up existing containers and images"; then
        print_warning "Cleanup had some issues, but continuing..."
    fi

    # Step 3: Build the Dev Container
    print_header "Step 3: Building Dev Container"
    if ! run_command "./scripts/devcontainer.sh build" "Build Dev Container image"; then
        print_error "Build failed! Check Docker and try again."
        exit 1
    fi

    # Step 4: Verify the build
    print_header "Step 4: Verifying Build"
    if run_command "docker images tzervas01/install-arch-dev --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'" "Check built image"; then
        print_info "Image details:"
        docker images tzervas01/install-arch-dev --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}'
    fi

    # Step 5: Test container functionality
    print_header "Step 5: Testing Container Functionality"
    print_info "Testing container by running a quick command..."
    if run_command "docker run --rm tzervas01/install-arch-dev:latest python3 --version" "Test Python in container"; then
        print_success "Container Python test passed"
    else
        print_error "Container test failed!"
        exit 1
    fi

    # Step 6: Run local CI checks (if available)
    print_header "Step 6: Running Local CI Checks"
    if [ -f "./scripts/run-local-ci.sh" ]; then
        if run_command "./scripts/run-local-ci.sh" "Run local CI checks"; then
            print_success "Local CI checks passed"
        else
            print_error "Local CI checks failed!"
            exit 1
        fi
    else
        print_info "Local CI script not found, skipping..."
    fi

    # Step 7: Show final status
    print_header "Step 7: Final Status Check"
    run_command "./scripts/devcontainer.sh status" "Final status check"

    # Success summary
    print_header "🎉 Automation Complete!"
    echo
    echo "Dev Container automation sequence completed successfully!"
    echo
    echo "Next steps:"
    echo "  • Open the project in VS Code"
    echo "  • Use 'Reopen in Container' to start developing"
    echo "  • Run 'make update' inside the container to set up dependencies"
    echo
    echo "Available commands:"
    echo "  • make status    - Check container status"
    echo "  • make update    - Update dependencies"
    echo "  • make test      - Run tests"
    echo "  • make ci        - Run full CI checks"
    echo
    print_success "All operations completed successfully!"
}

# Run main function
main "$@"