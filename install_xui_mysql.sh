#!/bin/bash

# x-ui MySQL Installation Script
# This script installs x-ui with MySQL support

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
            apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
            ;;
        "CentOS Linux"|"Red Hat Enterprise Linux"|"Rocky Linux")
            yum install -y curl wget git unzip yum-utils
            ;;
        *)
            print_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    
    print_status "System dependencies installed"
}

# Install Go
install_go() {
    print_step "Installing Go..."
    
    # Check if Go is already installed
    if command -v go &> /dev/null; then
        print_status "Go is already installed"
        return
    fi
    
    # Download and install Go
    GO_VERSION="1.21.0"
    GO_ARCH="linux-amd64"
    
    cd /tmp
    wget https://golang.org/dl/go${GO_VERSION}.${GO_ARCH}.tar.gz
    tar -C /usr/local -xzf go${GO_VERSION}.${GO_ARCH}.tar.gz
    
    # Add Go to PATH
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    source /etc/profile
    
    print_status "Go installed successfully"
}

# Install MySQL
install_mysql() {
    print_step "Installing MySQL..."
    
    case $OS in
        "Ubuntu"|"Debuntu GNU/Linux")
            # Install MySQL
            apt install -y mariadb-server mariadb-client
            
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
            # Install MySQL
            yum install -y mariadb-server mariadb
            
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

# Clone and build x-ui
build_xui() {
    print_step "Building x-ui..."
    
    # Create x-ui directory
    mkdir -p /usr/local/x-ui
    
    # Clone x-ui repository
    cd /usr/local/x-ui
    if [ -d ".git" ]; then
        print_status "Updating existing x-ui repository..."
        git pull
    else
        print_status "Cloning x-ui repository..."
        git clone https://github.com/cryptonceo/3x-ui.git .
    fi
    
    # Build x-ui
    print_status "Building x-ui..."
    go mod tidy
    go build -o x-ui main.go
    
    # Make executable
    chmod +x x-ui
    
    print_status "x-ui built successfully"
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
            # Install ufw if not present
            apt install -y ufw
            
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
    
    # Install Go
    install_go
    
    # Install MySQL
    install_mysql
    
    # Setup MySQL
    setup_mysql
    
    # Build x-ui
    build_xui
    
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