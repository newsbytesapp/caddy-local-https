#!/bin/bash

# Caddy Local HTTPS - Installation Script
# Supports Linux and macOS with Apache/nginx detection

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Helper functions
error() {
    echo -e "${RED}Error:${NC} $1" >&2
    exit 1
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}!${NC} $1"
}

info() {
    echo -e "${BLUE}→${NC} $1"
}

prompt() {
    echo -e "${YELLOW}?${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            DISTRO=$ID
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macos"
    else
        error "Unsupported operating system: $OSTYPE"
    fi
}

# Check if Docker is installed
check_docker() {
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
        success "Docker is installed (version $DOCKER_VERSION)"
        return 0
    else
        warning "Docker is not installed"
        return 1
    fi
}

# Check if Docker Compose is available
check_docker_compose() {
    if docker compose version &> /dev/null 2>&1; then
        success "Docker Compose V2 is available"
        COMPOSE_CMD="docker compose"
        return 0
    elif command -v docker-compose &> /dev/null; then
        success "Docker Compose V1 is available"
        COMPOSE_CMD="docker-compose"
        return 0
    else
        warning "Docker Compose is not available"
        return 1
    fi
}

# Install Docker on Linux
install_docker_linux() {
    info "Installing Docker on Linux..."

    case "$DISTRO" in
        ubuntu|debian)
            info "Detected Debian/Ubuntu"
            sudo apt-get update
            sudo apt-get install -y ca-certificates curl gnupg

            # Add Docker's official GPG key
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg

            # Add Docker repository
            echo \
              "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO \
              $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
              sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            # Install Docker
            sudo apt-get update
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;

        fedora)
            info "Detected Fedora"
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;

        centos|rhel)
            info "Detected CentOS/RHEL"
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;

        arch|manjaro)
            info "Detected Arch/Manjaro"
            sudo pacman -S --noconfirm docker docker-compose
            ;;

        *)
            error "Unsupported Linux distribution: $DISTRO. Please install Docker manually."
            ;;
    esac

    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    # Add current user to docker group
    sudo usermod -aG docker $USER

    success "Docker installed successfully"
    warning "You may need to log out and back in for group changes to take effect"
}

# Install Docker on macOS
install_docker_macos() {
    info "Installing Docker on macOS..."

    if command -v brew &> /dev/null; then
        info "Using Homebrew to install Docker Desktop"
        brew install --cask docker
        success "Docker Desktop installed via Homebrew"
        warning "Please start Docker Desktop from Applications before continuing"
    else
        warning "Homebrew not found"
        info "Please download and install Docker Desktop manually from:"
        info "https://www.docker.com/products/docker-desktop"
        error "Installation cannot continue without Docker"
    fi
}

# Detect web server on port 80
detect_webserver() {
    info "Checking for web server on port 80..."

    if [[ "$OS" == "macos" ]]; then
        PORT_CHECK=$(lsof -iTCP:80 -sTCP:LISTEN -n -P 2>/dev/null || true)
    else
        PORT_CHECK=$(ss -tlnp 2>/dev/null | grep ':80 ' || true)
    fi

    if [[ -n "$PORT_CHECK" ]]; then
        if echo "$PORT_CHECK" | grep -iq "apache\|httpd"; then
            WEB_SERVER="apache"
            success "Detected Apache on port 80"
        elif echo "$PORT_CHECK" | grep -iq "nginx"; then
            WEB_SERVER="nginx"
            success "Detected nginx on port 80"
        else
            WEB_SERVER="unknown"
            warning "Something is running on port 80, but couldn't identify the web server"
        fi
        return 0
    else
        warning "No web server detected on port 80"
        WEB_SERVER="none"
        return 1
    fi
}

# Check if port 443 is available
check_port_443() {
    info "Checking if port 443 is available..."

    if [[ "$OS" == "macos" ]]; then
        PORT_CHECK=$(lsof -iTCP:443 -sTCP:LISTEN -n -P 2>/dev/null || true)
    else
        PORT_CHECK=$(ss -tlnp 2>/dev/null | grep ':443 ' || true)
    fi

    if [[ -n "$PORT_CHECK" ]]; then
        error "Port 443 is already in use. Please free up this port before continuing.\nCurrently used by: $PORT_CHECK"
    else
        success "Port 443 is available"
    fi
}

# Install the caddy CLI globally
install_cli() {
    info "Installing caddy CLI globally..."

    # Make caddy script executable
    chmod +x "$SCRIPT_DIR/caddy"

    # Ask user where to install
    echo ""
    prompt "Where do you want to install the caddy CLI?"
    echo "  1) /usr/local/bin/caddy (system-wide, requires sudo)"
    echo "  2) ~/.local/bin/caddy (user only, no sudo required)"
    echo "  3) Skip CLI installation"
    read -p "Enter choice [1-3]: " install_choice

    case $install_choice in
        1)
            sudo ln -sf "$SCRIPT_DIR/caddy" /usr/local/bin/caddy
            success "Installed to /usr/local/bin/caddy"
            CLI_INSTALLED=true
            ;;
        2)
            mkdir -p ~/.local/bin
            ln -sf "$SCRIPT_DIR/caddy" ~/.local/bin/caddy
            success "Installed to ~/.local/bin/caddy"

            # Check if ~/.local/bin is in PATH
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                warning "~/.local/bin is not in your PATH"
                info "Add this to your ~/.bashrc or ~/.zshrc:"
                echo '  export PATH="$HOME/.local/bin:$PATH"'
            fi
            CLI_INSTALLED=true
            ;;
        3)
            info "Skipping CLI installation. Use ./caddy from the project directory"
            CLI_INSTALLED=false
            ;;
        *)
            warning "Invalid choice. Skipping CLI installation"
            CLI_INSTALLED=false
            ;;
    esac
}

# Main installation flow
main() {
    echo "╔════════════════════════════════════════╗"
    echo "║  Caddy Local HTTPS - Installation     ║"
    echo "╚════════════════════════════════════════╝"
    echo ""

    # Detect OS
    info "Detecting operating system..."
    detect_os
    success "Detected: $OS ($DISTRO)"
    echo ""

    # Check Docker
    if ! check_docker; then
        echo ""
        prompt "Docker is required. Do you want to install it? (y/n)"
        read -p "> " install_docker

        if [[ "$install_docker" =~ ^[Yy]$ ]]; then
            if [[ "$OS" == "linux" ]]; then
                install_docker_linux
            else
                install_docker_macos
            fi
            echo ""
        else
            error "Docker is required to continue. Please install it manually and run this script again."
        fi
    fi

    # Check Docker Compose
    echo ""
    if ! check_docker_compose; then
        if [[ "$OS" == "linux" ]]; then
            warning "Docker Compose is required but not found"
            info "It should have been installed with Docker. Please check your installation."
        fi
    fi

    # Detect web server
    echo ""
    detect_webserver

    if [[ "$WEB_SERVER" == "none" ]]; then
        warning "No web server detected on port 80"
        info "Caddy will proxy to port 80, but you need to have a web server running there"
        info "Common options: Apache, nginx"
        echo ""
        prompt "Do you want to continue anyway? (y/n)"
        read -p "> " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            error "Installation cancelled"
        fi
    fi

    # Check port 443
    echo ""
    check_port_443

    # Update docker-compose.yml if needed for macOS
    echo ""
    if [[ "$OS" == "macos" ]]; then
        info "macOS detected - host.docker.internal is built-in"
        success "No docker-compose.yml changes needed"
    else
        info "Linux detected - verifying docker-compose.yml configuration"
        if grep -q "host.docker.internal:host-gateway" "$SCRIPT_DIR/docker-compose.yml"; then
            success "docker-compose.yml is correctly configured for Linux"
        else
            warning "docker-compose.yml may need host-gateway configuration"
        fi
    fi

    # Start services
    echo ""
    info "Starting Caddy container..."
    cd "$SCRIPT_DIR"

    if [[ -n "$COMPOSE_CMD" ]]; then
        $COMPOSE_CMD up -d
    else
        docker-compose up -d
    fi

    success "Caddy container started"

    # Wait for container to be ready
    sleep 2

    # Check if container is running
    if docker ps | grep -q "caddy-local-https"; then
        success "Caddy is running"
    else
        error "Caddy container failed to start. Check logs with: docker logs caddy-local-https"
    fi

    # Install CLI globally
    echo ""
    install_cli

    # Display next steps
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║  Installation Complete!                ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    success "Caddy Local HTTPS is now installed and running"
    echo ""
    info "Next steps:"
    echo ""
    echo "1. Trust the CA certificate:"
    if [[ "$CLI_INSTALLED" == true ]]; then
        echo "   sudo caddy trust"
    else
        echo "   sudo ./caddy trust"
    fi
    echo ""
    echo "2. Add a domain:"
    if [[ "$CLI_INSTALLED" == true ]]; then
        echo "   caddy link myapp.test"
    else
        echo "   ./caddy link myapp.test"
    fi
    echo ""
    echo "3. View all commands:"
    if [[ "$CLI_INSTALLED" == true ]]; then
        echo "   caddy help"
    else
        echo "   ./caddy help"
    fi
    echo ""
    info "Web server detected: $WEB_SERVER"
    if [[ "$WEB_SERVER" == "apache" ]]; then
        info "Configure your Apache virtual hosts to listen on port 80"
    elif [[ "$WEB_SERVER" == "nginx" ]]; then
        info "Configure your nginx server blocks to listen on port 80"
    fi
    echo ""
    info "Documentation: $SCRIPT_DIR/README.md"
}

# Run main function
main
