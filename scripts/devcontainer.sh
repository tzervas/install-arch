#!/bin/bash
# Dev Container management automation script
# Provides commands to build, rebuild, clean, and manage the development container

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load configuration
source "$SCRIPT_DIR/config.sh"

# Debug mode
DEBUG=${DEBUG:-false}

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
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if we're in a Dev Container
is_in_devcontainer() {
    [ -n "${REMOTE_CONTAINERS+x}" ] || [ -n "${DEVCONTAINER+x}" ]
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running or not accessible"
        exit 1
    fi
}

# Build the Dev Container image
build() {
    debug "Starting build function"
    debug "Project root: $PROJECT_ROOT"
    debug "Dockerfile path: $PROJECT_ROOT/.devcontainer/Dockerfile"

    print_info "Building Dev Container image..."
    check_docker

    cd "$PROJECT_ROOT"

    # Show Dockerfile content in debug mode
    if [ "$DEBUG" = true ]; then
        debug "Dockerfile contents:"
        cat .devcontainer/Dockerfile | while IFS= read -r line; do
            debug "  $line"
        done
    fi

    # Check Docker Hub connectivity
    debug "Checking Docker Registry connectivity..."
    if curl -s --connect-timeout 5 "${INSTALL_ARCH_NETWORK_DOCKER_REGISTRY_URL}" > /dev/null 2>&1; then
        debug "Docker Registry is reachable"
    else
        debug "Docker Registry is not reachable - this may cause auth issues"
    fi

    debug "Running docker build command..."
    if [ "$DEBUG" = true ]; then
        docker build --progress=plain -t tzervas01/install-arch-dev:latest .devcontainer/
    else
        docker build -t tzervas01/install-arch-dev:latest .devcontainer/
    fi

    if [ $? -eq 0 ]; then
        print_success "Dev Container image built successfully"
        debug "Build completed successfully"
    else
        print_error "Failed to build Dev Container image"
        debug "Build failed with exit code $?"
        exit 1
    fi
}

# Rebuild the Dev Container (with no cache)
rebuild() {
    print_info "Rebuilding Dev Container image (no cache)..."
    check_docker

    cd "$PROJECT_ROOT"
    if docker build --no-cache -t install-arch-dev .devcontainer/; then
        print_success "Dev Container image rebuilt successfully"
    else
        print_error "Failed to rebuild Dev Container image"
        exit 1
    fi
}

# Clean up unused containers and images
clean() {
    print_info "Cleaning up Dev Container resources..."
    check_docker

    # Remove stopped containers with devcontainer labels
    stopped_containers=$(docker ps -aq --filter "label=devcontainer.local_folder=$PROJECT_ROOT" --filter "status=exited")
    if [ -n "$stopped_containers" ]; then
        print_info "Removing stopped Dev Containers..."
        echo "$stopped_containers" | xargs docker rm
        print_success "Removed stopped containers"
    else
        print_info "No stopped Dev Containers to clean"
    fi

    # Remove dangling images
    dangling_images=$(docker images -f "dangling=true" -q)
    if [ -n "$dangling_images" ]; then
        print_info "Removing dangling images..."
        echo "$dangling_images" | xargs docker rmi
        print_success "Removed dangling images"
    else
        print_info "No dangling images to clean"
    fi

    # Remove unused volumes
    print_info "Removing unused Docker volumes..."
    docker volume prune -f >/dev/null
    print_success "Cleaned unused volumes"
}

# Update the Dev Container dependencies
update() {
    if is_in_devcontainer; then
        print_info "Updating dependencies inside Dev Container..."

        # Update pacman packages
        if command -v pacman >/dev/null 2>&1; then
            print_info "Updating system packages..."
            sudo pacman -Syu --noconfirm
        fi

        # Update Python dependencies
        if command -v uv >/dev/null 2>&1; then
            print_info "Updating Python dependencies..."
            uv sync
            uv pip install -e .
        fi

        print_success "Dependencies updated"
    else
        print_warning "Not running inside a Dev Container. Run this command from within the container."
        exit 1
    fi
}

# Show Dev Container status
status() {
    print_info "Dev Container Status:"
    echo

    if is_in_devcontainer; then
        print_success "Running inside Dev Container"
        echo "  Workspace: $PWD"
        echo "  User: $(whoami)"
        if command -v python >/dev/null 2>&1; then
            echo "  Python: $(python --version)"
        fi
        if command -v uv >/dev/null 2>&1; then
            echo "  UV: $(uv --version)"
        fi
    else
        print_warning "Not running inside Dev Container"
        check_docker

        # Check if container is running
        running_container=$(docker ps -q --filter "label=devcontainer.local_folder=$PROJECT_ROOT")
        if [ -n "$running_container" ]; then
            print_success "Dev Container is running"
            echo "  Container ID: $running_container"
        else
            print_warning "No Dev Container currently running"
        fi

        # Check if image exists
        if docker images tzervas01/install-arch-dev -q >/dev/null 2>&1; then
            print_success "Dev Container image exists"
            echo "  Image: tzervas01/install-arch-dev"
        else
            print_warning "Dev Container image does not exist"
        fi
    fi
}

# Show usage information
usage() {
    cat << EOF
Dev Container Management Script

USAGE:
    $0 <command> [options]

COMMANDS:
    build       Build the Dev Container image
    rebuild     Rebuild the Dev Container image (no cache)
    clean       Clean up unused containers, images, and volumes
    update      Update dependencies inside the running container
    status      Show Dev Container status information

EXAMPLES:
    $0 build     # Build the Dev Container image
    $0 rebuild   # Force rebuild without cache
    $0 clean     # Clean up unused Docker resources
    $0 update    # Update dependencies (run inside container)
    $0 status    # Show current status

EOF
}

# Main command dispatcher
case "${1:-}" in
    build)
        build
        ;;
    rebuild)
        rebuild
        ;;
    clean)
        clean
        ;;
    update)
        update
        ;;
    status)
        status
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        print_error "Unknown command: ${1:-}"
        echo
        usage
        exit 1
        ;;
esac