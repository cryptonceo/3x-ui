#!/bin/bash

# Build Script for x-ui MySQL Release
# This script builds x-ui for Linux amd64 architecture

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if Go is installed
check_go() {
    if ! command -v go &> /dev/null; then
        print_error "Go is not installed. Please install Go 1.21 or later."
        exit 1
    fi
    
    GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    print_status "Found Go version: $GO_VERSION"
}

# Clean previous builds
clean_build() {
    print_step "Cleaning previous builds..."
    rm -rf build/
    rm -f x-ui-linux-amd64.tar.gz
    mkdir -p build/x-ui
}

# Build x-ui
build_xui() {
    print_step "Building x-ui for Linux amd64..."
    
    # Set environment variables for cross-compilation
    export GOOS=linux
    export GOARCH=amd64
    export CGO_ENABLED=0
    
    # Build the binary
    go mod tidy
    go build -ldflags="-s -w" -o build/x-ui/x-ui main.go
    
    print_status "x-ui binary built successfully"
}

# Copy necessary files
copy_files() {
    print_step "Copying necessary files..."
    
    # Copy service file
    cp x-ui.service build/x-ui/
    
    # Copy installation scripts
    cp install_mysql.sh build/x-ui/
    cp install_xui_mysql.sh build/x-ui/
    
    # Copy README
    cp README_MYSQL.md build/x-ui/README.md
    
    # Copy web assets
    cp -r web/ build/x-ui/
    
    # Copy other necessary directories
    cp -r config/ build/x-ui/
    cp -r database/ build/x-ui/
    cp -r logger/ build/x-ui/
    cp -r sub/ build/x-ui/
    cp -r util/ build/x-ui/
    cp -r xray/ build/x-ui/
    
    print_status "Files copied successfully"
}

# Create installation script
create_install_script() {
    print_step "Creating installation script..."
    
    cat > build/x-ui/install.sh <<'EOF'
#!/bin/bash

# x-ui MySQL Installation Script
# This script installs x-ui with MySQL support from release

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root"
   exit 1
fi

print_status "Starting x-ui installation with MySQL support..."

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    print_error "Cannot detect OS"
    exit 1
fi

print_status "Detected OS: $OS"

# Install system dependencies
install_dependencies() {
    print_step "Installing system dependencies..."
    
    case $OS in
        "Ubuntu"|"Debian GNU/Linux")
            apt update
            apt install -y curl wget mariadb-server mariadb-client ufw
            ;;
        "CentOS Linux"|"Red Hat Enterprise Linux"|"Rocky Linux")
            yum install -y curl wget mariadb-server mariadb
            ;;
        *)
            print_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    
    print_status "System dependencies installed"
}

# Install MySQL
install_mysql() {
    print_step "Installing MySQL..."
    
    case $OS in
        "Ubuntu"|"Debian GNU/Linux")
            # Start and enable MySQL
            systemctl start mariadb
            systemctl enable mariadb
            
            # Secure MySQL installation
            mysql_secure_installation <<EOF
y
2
y
y
y
y
EOF
            ;;
        "CentOS Linux"|"Red Hat Enterprise Linux"|"Rocky Linux")
            # Start and enable MySQL
            systemctl start mariadb
            systemctl enable mariadb
            
            # Secure MySQL installation
            mysql_secure_installation <<EOF
y
2
y
y
y
y
EOF
            ;;
    esac
    
    print_status "MySQL installed successfully"
}

# Setup MySQL for x-ui
setup_mysql() {
    print_step "Setting up MySQL for x-ui..."
    
    # Create database and user
    mysql -u root -e "
    CREATE DATABASE IF NOT EXISTS xui_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS 'xui_user'@'localhost' IDENTIFIED BY 'xui_password';
    GRANT ALL PRIVILEGES ON xui_db.* TO 'xui_user'@'localhost';
    FLUSH PRIVILEGES;
    "
    
    # Create MySQL configuration
    mkdir -p /etc/mysql/conf.d
    cat > /etc/mysql/conf.d/x-ui.cnf <<EOF
[mysqld]
# Character set
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# Connection settings
max_connections = 200
max_connect_errors = 1000

# Buffer settings
innodb_buffer_pool_size = 128M
innodb_log_file_size = 64M
innodb_log_buffer_size = 16M

# Query cache
query_cache_type = 1
query_cache_size = 32M

# Timeout settings
wait_timeout = 28800
interactive_timeout = 28800

# Logging
log_error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# Security
local_infile = 0
EOF

    # Restart MySQL
    systemctl restart mariadb
    
    print_status "MySQL setup completed"
}

# Install x-ui
install_xui() {
    print_step "Installing x-ui..."
    
    # Create x-ui directory
    mkdir -p /usr/local/x-ui
    
    # Copy x-ui binary and files
    cp x-ui /usr/local/x-ui/
    cp -r web/ /usr/local/x-ui/
    cp -r config/ /usr/local/x-ui/
    cp -r database/ /usr/local/x-ui/
    cp -r logger/ /usr/local/x-ui/
    cp -r sub/ /usr/local/x-ui/
    cp -r util/ /usr/local/x-ui/
    cp -r xray/ /usr/local/x-ui/
    
    # Make executable
    chmod +x /usr/local/x-ui/x-ui
    
    print_status "x-ui installed successfully"
}

# Setup environment
setup_environment() {
    print_step "Setting up environment..."
    
    # Create x-ui configuration directory
    mkdir -p /etc/x-ui
    
    # Create environment file
    cat > /etc/x-ui/.env <<EOF
# x-ui Database Configuration
XUI_DB_TYPE=mysql
XUI_DB_DSN=xui_user:xui_password@tcp(127.0.0.1:3306)/xui_db?charset=utf8mb4&parseTime=True&loc=Local

# x-ui Application Configuration
XUI_LOG_LEVEL=info
XUI_DEBUG=false
XUI_BIN_FOLDER=/usr/local/x-ui/bin
XUI_DB_FOLDER=/etc/x-ui
XUI_LOG_FOLDER=/var/log/x-ui
EOF

    # Set proper permissions
    chmod 600 /etc/x-ui/.env
    
    print_status "Environment configured"
}

# Setup systemd service
setup_systemd() {
    print_step "Setting up systemd service..."
    
    # Copy service file
    cp x-ui.service /etc/systemd/system/x-ui.service
    
    # Create systemd override directory
    mkdir -p /etc/systemd/system/x-ui.service.d
    
    # Create override file
    cat > /etc/systemd/system/x-ui.service.d/override.conf <<EOF
[Service]
EnvironmentFile=/etc/x-ui/.env
EOF

    # Reload systemd
    systemctl daemon-reload
    
    # Enable service
    systemctl enable x-ui.service
    
    print_status "Systemd service configured"
}

# Setup firewall
setup_firewall() {
    print_step "Setting up firewall..."
    
    case $OS in
        "Ubuntu"|"Debian GNU/Linux")
            # Configure firewall
            ufw allow 22/tcp
            ufw allow 54321/tcp  # Default x-ui port
            ufw --force enable
            ;;
        "CentOS Linux"|"Red Hat Enterprise Linux"|"Rocky Linux")
            # Configure firewall
            firewall-cmd --permanent --add-port=22/tcp
            firewall-cmd --permanent --add-port=54321/tcp
            firewall-cmd --reload
            ;;
    esac
    
    print_status "Firewall configured"
}

# Main installation process
main() {
    print_status "Starting x-ui installation with MySQL support..."
    
    # Install dependencies
    install_dependencies
    
    # Install MySQL
    install_mysql
    
    # Setup MySQL
    setup_mysql
    
    # Install x-ui
    install_xui
    
    # Setup environment
    setup_environment
    
    # Setup systemd
    setup_systemd
    
    # Setup firewall
    setup_firewall
    
    print_status "Installation completed successfully!"
    print_status ""
    print_status "Next steps:"
    print_status "1. Start x-ui: systemctl start x-ui"
    print_status "2. Check status: systemctl status x-ui"
    print_status "3. View logs: journalctl -u x-ui -f"
    print_status "4. Access panel: http://your-server-ip:54321"
    print_status "5. Default credentials: admin/admin"
    print_status ""
    print_status "MySQL database: xui_db"
    print_status "MySQL user: xui_user"
    print_status "MySQL password: xui_password"
}

# Run main function
main "$@"
EOF

    chmod +x build/x-ui/install.sh
    print_status "Installation script created"
}

# Create tar.gz archive
create_archive() {
    print_step "Creating release archive..."
    
    cd build
    tar -czf ../x-ui-linux-amd64.tar.gz x-ui/
    cd ..
    
    print_status "Release archive created: x-ui-linux-amd64.tar.gz"
}

# Main build process
main() {
    print_status "Starting x-ui build process..."
    
    # Check Go installation
    check_go
    
    # Clean previous builds
    clean_build
    
    # Build x-ui
    build_xui
    
    # Copy files
    copy_files
    
    # Create installation script
    create_install_script
    
    # Create archive
    create_archive
    
    print_status "Build completed successfully!"
    print_status "Release file: x-ui-linux-amd64.tar.gz"
    print_status "Size: $(du -h x-ui-linux-amd64.tar.gz | cut -f1)"
}

# Run main function
main "$@" 