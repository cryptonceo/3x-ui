#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# Check root
[[ $EUID -ne 0 ]] && echo -e "${red}Fatal error: ${plain} Please run this script with root privilege \n " && exit 1

# Check OS and set release variable
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "Failed to check the system OS, please contact the author!" >&2
    exit 1
fi
echo "The OS release is: $release"

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${green}Unsupported CPU architecture! ${plain}" && rm -f install.sh && exit 1 ;;
    esac
}

echo "Arch: $(arch)"

check_glibc_version() {
    glibc_version=$(ldd --version | head -n1 | awk '{print $NF}')
    required_version="2.32"
    if [[ "$(printf '%s\n' "$required_version" "$glibc_version" | sort -V | head -n1)" != "$required_version" ]]; then
        echo -e "${red}GLIBC version $glibc_version is too old! Required: 2.32 or higher${plain}"
        echo "Please upgrade to a newer version of your operating system to get a higher GLIBC version."
        exit 1
    fi
    echo "GLIBC version: $glibc_version (meets requirement of 2.32+)"
}
check_glibc_version

install_base() {
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -y -q wget curl tar tzdata mariadb-server fail2ban ufw unzip git
        ;;
    centos | rhel | almalinux | rocky | ol)
        yum -y update && yum install -y -q wget curl tar tzdata mariadb-server fail2ban ufw unzip git
        ;;
    fedora | amzn | virtuozzo)
        dnf -y update && dnf install -y -q wget curl tar tzdata mariadb-server fail2ban ufw unzip git
        ;;
    arch | manjaro | parch)
        pacman -Syu && pacman -Syu --noconfirm wget curl tar tzdata mariadb fail2ban ufw unzip git
        ;;
    opensuse-tumbleweed)
        zypper refresh && zypper -q install -y wget curl tar timezone mariadb fail2ban ufw unzip git
        ;;
    *)
        apt-get update && apt install -y -q wget curl tar tzdata mariadb-server fail2ban ufw unzip git
        ;;
    esac
    # Configure UFW
    ufw allow 22
    ufw allow 80
    ufw allow 443
    ufw --force enable
    # Configure Fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban
}

setup_mysql() {
    echo -e "${green}Setting up MySQL/MariaDB for x-ui...${plain}"
    
    # Start and enable MySQL service
    systemctl start mariadb
    systemctl enable mariadb

    # Secure MySQL installation
    echo -e "${yellow}Securing MySQL installation...${plain}"
    mysql_secure_installation <<EOF
y
2
y
y
y
y
EOF

    # Create database and user for x-ui
    echo -e "${green}Creating MySQL database and user for x-ui...${plain}"
    mysql -u root -e "
    CREATE DATABASE IF NOT EXISTS xui_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER IF NOT EXISTS 'xui_user'@'localhost' IDENTIFIED BY 'xui_password';
    GRANT ALL PRIVILEGES ON xui_db.* TO 'xui_user'@'localhost';
    FLUSH PRIVILEGES;
    "

    # Create MySQL configuration for x-ui
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

    # Restart MySQL to apply configuration
    systemctl restart mariadb
    
    echo -e "${green}MySQL setup completed successfully!${plain}"
    echo -e "${green}Database: xui_db${plain}"
    echo -e "${green}User: xui_user${plain}"
    echo -e "${green}Password: xui_password${plain}"
}

setup_environment() {
    echo -e "${green}Setting up environment variables...${plain}"
    
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
    
    echo -e "${green}Environment configured successfully!${plain}"
}

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

config_after_install() {
    local existing_hasDefaultCredential=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'hasDefaultCredential: .+' | awk '{print $2}')
    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'port: .+' | awk '{print $2}')
    local server_ip=$(curl -s https://api.ipify.org)

    if [[ ${#existing_webBasePath} -lt 4 ]]; then
        if [[ "$existing_hasDefaultCredential" == "true" ]]; then
            local config_webBasePath=$(gen_random_string 15)
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            read -rp "Would you like to customize the Panel Port settings? (If not, a random port will be applied) [y/n]: " config_confirm
            if [[ "${config_confirm}" == "y" || "${config_confirm}" == "Y" ]]; then
                read -rp "Please set up the panel port: " config_port
                echo -e "${yellow}Your Panel Port is: ${config_port}${plain}"
            else
                local config_port=$(shuf -i 1024-62000 -n 1)
                echo -e "${yellow}Generated random port: ${config_port}${plain}"
            fi

            /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}" -port "${config_port}" -webBasePath "${config_webBasePath}"
            echo -e "This is a fresh installation, generating random login info for security concerns:"
            echo -e "###############################################"
            echo -e "${green}Username: ${config_username}${plain}"
            echo -e "${green}Password: ${config_password}${plain}"
            echo -e "${green}Port: ${config_port}${plain}"
            echo -e "${green}WebBasePath: ${config_webBasePath}${plain}"
            echo -e "${green}Access URL: http://${server_ip}:${config_port}/${config_webBasePath}${plain}"
            echo -e "###############################################"
        else
            local config_webBasePath=$(gen_random_string 15)
            echo -e "${yellow}WebBasePath is missing or too short. Generating a new one...${plain}"
            /usr/local/x-ui/x-ui setting -webBasePath "${config_webBasePath}"
            echo -e "${green}New WebBasePath: ${config_webBasePath}${plain}"
            echo -e "${green}Access URL: http://${server_ip}:${existing_port}/${config_webBasePath}${plain}"
        fi
    else
        if [[ "$existing_hasDefaultCredential" == "true" ]]; then
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            echo -e "${yellow}Default credentials detected. Security update required...${plain}"
            /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}"
            echo -e "Generated new random login credentials:"
            echo -e "###############################################"
            echo -e "${green}Username: ${config_username}${plain}"
            echo -e "${green}Password: ${config_password}${plain}"
            echo -e "###############################################"
        else
            echo -e "${green}Username, Password, and WebBasePath are properly set. Exiting...${plain}"
        fi
    fi

    /usr/local/x-ui/x-ui migrate
}

install_x-ui() {
    cd /usr/local/

    if [ $# == 0 ]; then
        # Use our modified version instead of the original
        echo -e "${green}Installing x-ui with MySQL support...${plain}"
        
        # Check if we're in the x-ui directory with our modified version
        if [[ -f "main.go" && -f "go.mod" ]]; then
            echo -e "${green}Building x-ui from source with MySQL support...${plain}"
            
            # Build x-ui
            export GOOS=linux
            export GOARCH=$(arch)
            export CGO_ENABLED=0
            
            go mod tidy
            go build -ldflags="-s -w" -o x-ui main.go
            
            if [[ $? -ne 0 ]]; then
                echo -e "${red}Failed to build x-ui. Please make sure Go is installed.${plain}"
                exit 1
            fi
            
            # Create x-ui directory structure
            mkdir -p x-ui
            mv x-ui x-ui/x-ui
            cp -r web/ x-ui/
            cp -r config/ x-ui/
            cp -r database/ x-ui/
            cp -r logger/ x-ui/
            cp -r sub/ x-ui/
            cp -r util/ x-ui/
            cp -r xray/ x-ui/
            cp x-ui.service x-ui/
            
            chmod +x x-ui/x-ui
            cd x-ui
            
        else
            echo -e "${red}Please run this script from the x-ui source directory with MySQL modifications.${plain}"
            exit 1
        fi
    else
        echo -e "${red}Custom version installation not supported with MySQL version.${plain}"
        exit 1
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        systemctl stop x-ui
        rm /usr/local/x-ui/ -rf
    fi

    # Setup MySQL before installing x-ui
    setup_mysql
    
    # Setup environment variables
    setup_environment

    # Copy x-ui files to /usr/local/x-ui
    cp -r * /usr/local/x-ui/
    cd /usr/local/x-ui

    # Check the system's architecture and rename the file accordingly
    if [[ $(arch) == "armv5" || $(arch) == "armv6" || $(arch) == "armv7" ]]; then
        if [[ -f "bin/xray-linux-$(arch)" ]]; then
            mv bin/xray-linux-$(arch) bin/xray-linux-arm
            chmod +x bin/xray-linux-arm
        fi
    fi

    chmod +x x-ui
    if [[ -f "bin/xray-linux-$(arch)" ]]; then
        chmod +x bin/xray-linux-$(arch)
    fi
    
    # Copy service file with MySQL environment
    cp -f x-ui.service /etc/systemd/system/
    
    # Create systemd override for environment variables
    mkdir -p /etc/systemd/system/x-ui.service.d
    cat > /etc/systemd/system/x-ui.service.d/override.conf <<EOF
[Service]
EnvironmentFile=/etc/x-ui/.env
EOF

    # Create x-ui command
    cat > /usr/bin/x-ui <<EOF
#!/bin/bash
/usr/local/x-ui/x-ui "\$@"
EOF
    chmod +x /usr/bin/x-ui
    
    config_after_install

    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    
    echo -e "${green}x-ui with MySQL support installation finished, it is running now...${plain}"
    echo -e ""
    echo -e "┌───────────────────────────────────────────────────────┐
│  ${blue}x-ui control menu usages (subcommands):${plain}              │
│                                                       │
│  ${blue}x-ui${plain}              - Admin Management Script          │
│  ${blue}x-ui start${plain}        - Start                            │
│  ${blue}x-ui stop${plain}         - Stop                             │
│  ${blue}x-ui restart${plain}      - Restart                          │
│  ${blue}x-ui status${plain}       - Current Status                   │
│  ${blue}x-ui settings${plain}     - Current Settings                 │
│  ${blue}x-ui enable${plain}       - Enable Autostart on OS Startup   │
│  ${blue}x-ui disable${plain}      - Disable Autostart on OS Startup  │
│  ${blue}x-ui log${plain}          - Check logs                       │
│  ${blue}x-ui banlog${plain}       - Check Fail2ban ban logs          │
│  ${blue}x-ui update${plain}       - Update                           │
│  ${blue}x-ui legacy${plain}       - legacy version                   │
│  ${blue}x-ui install${plain}      - Install                          │
│  ${blue}x-ui uninstall${plain}    - Uninstall                        │
└───────────────────────────────────────────────────────┘"
    echo -e ""
    echo -e "${green}MySQL Database Information:${plain}"
    echo -e "${green}Database: xui_db${plain}"
    echo -e "${green}User: xui_user${plain}"
    echo -e "${green}Password: xui_password${plain}"
    echo -e "${green}Host: localhost:3306${plain}"
}

echo -e "${green}Running x-ui installation with MySQL support...${plain}"
install_base
install_x-ui $1 