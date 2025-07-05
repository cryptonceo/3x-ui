#!/bin/bash

# x-ui MySQL Installation Script
# Usage: bash <(curl -Ls https://raw.githubusercontent.com/cryptonceo/x-ui/master/install_mysql.sh)

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

echo -e "${green}Installing x-ui with MySQL support...${plain}"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${red}This script must be run as root${plain}"
   exit 1
fi

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    echo -e "${red}Cannot detect OS${plain}"
    exit 1
fi

echo -e "${green}Detected OS: $OS${plain}"

# Install system dependencies
install_dependencies() {
    echo -e "${blue}Installing system dependencies...${plain}"
    
    case $OS in
        "Ubuntu"|"Debian GNU/Linux")
            apt update
            apt install -y curl wget mariadb-server mariadb-client ufw fail2ban git golang-go
            ;;
        "CentOS Linux"|"Red Hat Enterprise Linux"|"Rocky Linux")
            yum install -y curl wget mariadb-server mariadb git golang
            ;;
        *)
            echo -e "${red}Unsupported OS: $OS${plain}"
            exit 1
            ;;
    esac
    
    echo -e "${green}System dependencies installed${plain}"
}

# Install MySQL
install_mysql() {
    echo -e "${blue}Installing MySQL...${plain}"
    
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
    
    echo -e "${green}MySQL installed successfully${plain}"
}

# Setup MySQL for x-ui
setup_mysql() {
    echo -e "${blue}Setting up MySQL for x-ui...${plain}"
    
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
    
    echo -e "${green}MySQL setup completed${plain}"
}

# Download and build x-ui
download_and_build() {
    echo -e "${blue}Downloading and building x-ui...${plain}"
    
    # Create temporary directory
    mkdir -p /tmp/x-ui-build
    cd /tmp/x-ui-build
    
    # Download x-ui source (you need to replace with your actual repository)
    git clone https://github.com/cryptonceo/x-ui.git .
    
    # Build x-ui
    export GOOS=linux
    export GOARCH=amd64
    export CGO_ENABLED=0
    
    go mod tidy
    go build -ldflags="-s -w" -o x-ui main.go
    
    if [[ $? -ne 0 ]]; then
        echo -e "${red}Failed to build x-ui${plain}"
        exit 1
    fi
    
    echo -e "${green}x-ui built successfully${plain}"
}

# Install x-ui
install_xui() {
    echo -e "${blue}Installing x-ui...${plain}"
    
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
    
    echo -e "${green}x-ui installed successfully${plain}"
}

# Setup environment
setup_environment() {
    echo -e "${blue}Setting up environment...${plain}"
    
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
    
    echo -e "${green}Environment configured${plain}"
}

# Setup systemd service
setup_systemd() {
    echo -e "${blue}Setting up systemd service...${plain}"
    
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
    
    echo -e "${green}Systemd service configured${plain}"
}

# Setup firewall
setup_firewall() {
    echo -e "${blue}Setting up firewall...${plain}"
    
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
    
    echo -e "${green}Firewall configured${plain}"
}

# Generate random credentials
generate_credentials() {
    echo -e "${blue}Generating random credentials...${plain}"
    
    # Generate random username and password
    USERNAME=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
    PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
    PORT=$(shuf -i 1024-62000 -n 1)
    WEBPATH=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
    
    # Configure x-ui
    /usr/local/x-ui/x-ui setting -username "$USERNAME" -password "$PASSWORD" -port "$PORT" -webBasePath "$WEBPATH"
    
    echo -e "${green}Credentials generated successfully${plain}"
    echo -e "${green}Username: $USERNAME${plain}"
    echo -e "${green}Password: $PASSWORD${plain}"
    echo -e "${green}Port: $PORT${plain}"
    echo -e "${green}WebBasePath: $WEBPATH${plain}"
}

# Main installation process
main() {
    echo -e "${green}Starting x-ui installation with MySQL support...${plain}"
    
    # Install dependencies
    install_dependencies
    
    # Install MySQL
    install_mysql
    
    # Setup MySQL
    setup_mysql
    
    # Download and build x-ui
    download_and_build
    
    # Install x-ui
    install_xui
    
    # Setup environment
    setup_environment
    
    # Setup systemd
    setup_systemd
    
    # Setup firewall
    setup_firewall
    
    # Generate credentials
    generate_credentials
    
    # Start x-ui
    systemctl start x-ui
    
    echo -e "${green}Installation completed successfully!${plain}"
    echo -e ""
    echo -e "${green}Next steps:${plain}"
    echo -e "${green}1. Check status: systemctl status x-ui${plain}"
    echo -e "${green}2. View logs: journalctl -u x-ui -f${plain}"
    echo -e "${green}3. Access panel: http://your-server-ip:$PORT/$WEBPATH${plain}"
    echo -e "${green}4. Login with: $USERNAME / $PASSWORD${plain}"
    echo -e ""
    echo -e "${green}MySQL database: xui_db${plain}"
    echo -e "${green}MySQL user: xui_user${plain}"
    echo -e "${green}MySQL password: xui_password${plain}"
    
    # Clean up
    cd /
    rm -rf /tmp/x-ui-build
}

# Run main function
main "$@" 