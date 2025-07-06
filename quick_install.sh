#!/bin/bash

# Быстрый скрипт установки 3x-ui MySQL Edition
# Автор: AI Assistant
# Версия: 1.0

set -e

echo "=== Быстрая установка 3x-ui MySQL Edition ==="

# Проверяем права sudo
if [ "$EUID" -ne 0 ]; then
    echo "Этот скрипт должен быть запущен с правами sudo"
    exit 1
fi

# Устанавливаем MySQL если не установлен
if ! command -v mysql &> /dev/null; then
    echo "Установка MySQL..."
    apt-get update
    apt-get install -y mysql-server
    systemctl start mysql
    systemctl enable mysql
fi

# Настраиваем MySQL
echo "Настройка MySQL..."
mysql -e "CREATE DATABASE IF NOT EXISTS \`3x-ui\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS 'root'@'localhost' IDENTIFIED BY 'frif2003';"
mysql -e "GRANT ALL PRIVILEGES ON \`3x-ui\`.* TO 'root'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Устанавливаем Go если не установлен
if ! command -v go &> /dev/null; then
    echo "Установка Go..."
    wget https://go.dev/dl/go1.24.4.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.24.4.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    rm go1.24.4.linux-amd64.tar.gz
fi

# Собираем проект
echo "Сборка проекта..."
go mod tidy
GOOS=linux GOARCH=amd64 go build -o x-ui main.go

# Создаем директории
mkdir -p /usr/local/x-ui
mkdir -p /var/log/x-ui

# Копируем файлы
cp x-ui /usr/local/x-ui/
cp -r web /usr/local/x-ui/
cp -r config /usr/local/x-ui/
cp -r database /usr/local/x-ui/
cp -r logger /usr/local/x-ui/
cp -r sub /usr/local/x-ui/
cp -r util /usr/local/x-ui/
cp -r xray /usr/local/x-ui/

# Устанавливаем права
chmod +x /usr/local/x-ui/x-ui
chown -R root:root /usr/local/x-ui

# Создаем systemd сервис
cat > /etc/systemd/system/x-ui.service << EOF
[Unit]
Description=3x-ui Panel
After=network.target mysql.service
Wants=mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/x-ui
ExecStart=/usr/local/x-ui/x-ui
Restart=on-failure
RestartSec=5s
Environment=XUI_MYSQL_HOST=localhost
Environment=XUI_MYSQL_PORT=3306
Environment=XUI_MYSQL_USER=root
Environment=XUI_MYSQL_PASSWORD=frif2003
Environment=XUI_MYSQL_DATABASE=3x-ui

[Install]
WantedBy=multi-user.target
EOF

# Перезагружаем systemd и запускаем сервис
systemctl daemon-reload
systemctl start x-ui
systemctl enable x-ui

# Проверяем статус
echo "Проверка статуса..."
sleep 5
systemctl status x-ui --no-pager -l

echo ""
echo "=== Установка завершена ==="
echo "Панель доступна по адресу: http://$(hostname -I | awk '{print $1}'):54321"
echo "Логин: admin"
echo "Пароль: admin"
echo ""
echo "Для проверки подключения к MySQL выполните:"
echo "chmod +x test_mysql_connection.sh && ./test_mysql_connection.sh" 