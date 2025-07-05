# x-ui with MySQL Support

This is a modified version of x-ui that supports MySQL database instead of SQLite. The application has been updated to work seamlessly with MySQL while maintaining all original functionality.

## Features

- ✅ Full MySQL support with automatic database setup
- ✅ Improved performance compared to SQLite
- ✅ Better concurrent user handling
- ✅ Automatic MySQL installation and configuration
- ✅ Systemd service integration
- ✅ Environment-based configuration
- ✅ Firewall configuration
- ✅ All original x-ui features

## Quick Installation

### Option 1: Automated Installation (Recommended)

```bash
# Download and run the installation script
curl -Ls https://raw.githubusercontent.com/your-repo/x-ui-mysql/main/install_xui_mysql.sh | sudo bash
```

### Option 2: Manual Installation

```bash
# Clone the repository
git clone https://github.com/your-repo/x-ui-mysql.git
cd x-ui-mysql

# Make scripts executable
chmod +x install_xui_mysql.sh
chmod +x install_mysql.sh

# Run installation
sudo ./install_xui_mysql.sh
```

## Manual Setup

If you prefer to set up manually:

### 1. Install Dependencies

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y curl wget git unzip mariadb-server mariadb-client

# CentOS/RHEL/Rocky Linux
sudo yum install -y curl wget git unzip mariadb-server mariadb
```

### 2. Install Go

```bash
# Download Go
wget https://golang.org/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz

# Add to PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```

### 3. Setup MySQL

```bash
# Start and enable MySQL
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Secure MySQL installation
sudo mysql_secure_installation

# Create database and user
sudo mysql -u root -p
```

In MySQL prompt:
```sql
CREATE DATABASE xui_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'xui_user'@'localhost' IDENTIFIED BY 'xui_password';
GRANT ALL PRIVILEGES ON xui_db.* TO 'xui_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 4. Build x-ui

```bash
# Clone repository
git clone https://github.com/your-repo/x-ui-mysql.git
cd x-ui-mysql

# Build
go mod tidy
go build -o x-ui main.go
```

### 5. Configure Environment

```bash
# Create configuration directory
sudo mkdir -p /etc/x-ui

# Create environment file
sudo tee /etc/x-ui/.env > /dev/null <<EOF
XUI_DB_TYPE=mysql
XUI_DB_DSN=xui_user:xui_password@tcp(127.0.0.1:3306)/xui_db?charset=utf8mb4&parseTime=True&loc=Local
XUI_LOG_LEVEL=info
XUI_DEBUG=false
EOF

# Set permissions
sudo chmod 600 /etc/x-ui/.env
```

### 6. Setup Systemd Service

```bash
# Copy service file
sudo cp x-ui.service /etc/systemd/system/

# Create override directory
sudo mkdir -p /etc/systemd/system/x-ui.service.d

# Create override file
sudo tee /etc/systemd/system/x-ui.service.d/override.conf > /dev/null <<EOF
[Service]
EnvironmentFile=/etc/x-ui/.env
EOF

# Reload systemd
sudo systemctl daemon-reload
sudo systemctl enable x-ui.service
```

### 7. Start x-ui

```bash
# Start the service
sudo systemctl start x-ui

# Check status
sudo systemctl status x-ui

# View logs
sudo journalctl -u x-ui -f
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `XUI_DB_TYPE` | Database type (mysql/sqlite) | mysql |
| `XUI_DB_DSN` | MySQL connection string | xui_user:xui_password@tcp(127.0.0.1:3306)/xui_db?charset=utf8mb4&parseTime=True&loc=Local |
| `XUI_LOG_LEVEL` | Log level (debug/info/notice/warn/error) | info |
| `XUI_DEBUG` | Enable debug mode | false |

### MySQL Configuration

The application automatically creates the MySQL database and tables. The default configuration:

- **Database**: `xui_db`
- **User**: `xui_user`
- **Password**: `xui_password`
- **Host**: `127.0.0.1`
- **Port**: `3306`

## Usage

### Start x-ui
```bash
sudo systemctl start x-ui
```

### Stop x-ui
```bash
sudo systemctl stop x-ui
```

### Restart x-ui
```bash
sudo systemctl restart x-ui
```

### Check Status
```bash
sudo systemctl status x-ui
```

### View Logs
```bash
sudo journalctl -u x-ui -f
```

### Access Panel
- **URL**: `http://your-server-ip:54321`
- **Default Username**: `admin`
- **Default Password**: `admin`

## Troubleshooting

### MySQL Connection Issues

1. **Check MySQL Status**:
```bash
sudo systemctl status mariadb
```

2. **Check MySQL Logs**:
```bash
sudo tail -f /var/log/mysql/error.log
```

3. **Test MySQL Connection**:
```bash
mysql -u xui_user -p xui_db
```

### x-ui Service Issues

1. **Check Service Status**:
```bash
sudo systemctl status x-ui
```

2. **View Service Logs**:
```bash
sudo journalctl -u x-ui -f
```

3. **Check Environment Variables**:
```bash
sudo systemctl show x-ui --property=Environment
```

### Database Migration

If you're migrating from SQLite to MySQL:

```bash
# Stop x-ui
sudo systemctl stop x-ui

# Export data from SQLite (if needed)
# Import data to MySQL (if needed)

# Start x-ui with MySQL
sudo systemctl start x-ui
```

## Security Considerations

1. **Change Default Passwords**:
   - Change the default x-ui admin password
   - Change the MySQL root password
   - Change the xui_user password

2. **Firewall Configuration**:
   - Only allow necessary ports (22, 54321)
   - Consider using a reverse proxy

3. **SSL/TLS**:
   - Configure SSL certificates for secure access
   - Use HTTPS instead of HTTP

## Performance Tuning

### MySQL Optimization

Edit `/etc/mysql/conf.d/x-ui.cnf`:

```ini
[mysqld]
# Increase buffer pool size for better performance
innodb_buffer_pool_size = 256M

# Optimize for read-heavy workloads
innodb_read_io_threads = 8
innodb_write_io_threads = 8

# Enable query cache
query_cache_type = 1
query_cache_size = 64M
```

### System Optimization

```bash
# Increase file descriptor limits
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf

# Optimize kernel parameters
echo "net.core.somaxconn = 65535" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 65535" >> /etc/sysctl.conf
sysctl -p
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:

- Create an issue on GitHub
- Check the troubleshooting section
- Review the logs for error messages

## Changelog

### Version 2.6.1-MySQL
- Added MySQL support
- Improved database initialization
- Enhanced error handling
- Added automatic MySQL setup
- Updated systemd service configuration
- Added comprehensive installation scripts 