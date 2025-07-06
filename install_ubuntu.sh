#!/bin/bash

# Полный скрипт установки 3x-ui MySQL Edition для Ubuntu
# Автор: AI Assistant
# Версия: 1.0

set -e

echo "=== Полная установка 3x-ui MySQL Edition для Ubuntu ==="

# Проверяем, что мы на Ubuntu/Debian
if ! command -v apt-get &> /dev/null; then
    echo "Ошибка: Этот скрипт предназначен для Ubuntu/Debian систем"
    exit 1
fi

# Проверяем права sudo
if [ "$EUID" -ne 0 ]; then
    echo "Этот скрипт должен быть запущен с правами sudo"
    exit 1
fi

# Обновляем систему
echo "Обновление системы..."
apt-get update
apt-get upgrade -y

# Устанавливаем необходимые пакеты
echo "Установка необходимых пакетов..."
apt-get install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Устанавливаем MySQL
echo "Установка MySQL Server..."
apt-get install -y mysql-server

# Запускаем MySQL сервис
echo "Запуск MySQL сервиса..."
systemctl start mysql
systemctl enable mysql

# Настраиваем MySQL
echo "Настройка MySQL..."

# Создаем временный файл с SQL командами
cat > /tmp/mysql_setup.sql << EOF
-- Создаем базу данных
CREATE DATABASE IF NOT EXISTS \`3x-ui\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Создаем пользователя и даем права
CREATE USER IF NOT EXISTS 'root'@'localhost' IDENTIFIED BY 'frif2003';
GRANT ALL PRIVILEGES ON \`3x-ui\`.* TO 'root'@'localhost';
FLUSH PRIVILEGES;

-- Показываем созданные базы данных
SHOW DATABASES;
EOF

# Выполняем SQL команды
echo "Выполнение SQL команд..."
mysql < /tmp/mysql_setup.sql

# Удаляем временный файл
rm /tmp/mysql_setup.sql

# Устанавливаем Go
echo "Установка Go..."
if ! command -v go &> /dev/null; then
    wget https://go.dev/dl/go1.24.4.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.24.4.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    export PATH=$PATH:/usr/local/go/bin
    rm go1.24.4.linux-amd64.tar.gz
fi

# Проверяем версию Go
echo "Версия Go:"
go version

# Создаем директорию для проекта
echo "Создание директории проекта..."
mkdir -p /opt/3x-ui
cd /opt/3x-ui

# Клонируем репозиторий (замените на ваш URL)
echo "Клонирование репозитория..."
# git clone https://github.com/your-username/3x-ui-mysql.git .
# cd 3x-ui-mysql

# Очищаем кэш модулей
echo "Очистка кэша модулей..."
go clean -modcache

# Скачиваем зависимости
echo "Скачивание зависимостей..."
go mod download

# Проверяем зависимости
echo "Проверка зависимостей..."
go mod tidy

# Собираем проект
echo "Сборка проекта..."
GOOS=linux GOARCH=amd64 go build -o x-ui main.go

# Проверяем, что бинарный файл создан
if [ -f "x-ui" ]; then
    echo "=== Сборка успешно завершена ==="
    echo "Бинарный файл: x-ui"
    echo "Размер: $(du -h x-ui | cut -f1)"
    echo "Архитектура: $(file x-ui | grep -o 'ELF [0-9]*-bit')"
else
    echo "Ошибка: Бинарный файл не создан"
    exit 1
fi

# Создаем systemd сервис
echo "Создание systemd сервиса..."
tee /etc/systemd/system/x-ui.service > /dev/null << EOF
[Unit]
Description=3x-ui Panel
After=network.target mysql.service
Wants=mysql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/3x-ui
ExecStart=/opt/3x-ui/x-ui
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

# Создаем директорию для установки
echo "Создание директории установки..."
mkdir -p /usr/local/x-ui

# Копируем файлы
echo "Копирование файлов..."
cp x-ui /usr/local/x-ui/
cp -r web /usr/local/x-ui/
cp -r config /usr/local/x-ui/
cp -r database /usr/local/x-ui/
cp -r logger /usr/local/x-ui/
cp -r sub /usr/local/x-ui/
cp -r util /usr/local/x-ui/
cp -r xray /usr/local/x-ui/

# Устанавливаем права
echo "Установка прав доступа..."
chmod +x /usr/local/x-ui/x-ui
chown -R root:root /usr/local/x-ui

# Создаем директории для логов
echo "Создание директорий для логов..."
mkdir -p /var/log/x-ui
chown -R root:root /var/log/x-ui

# Перезагружаем systemd
echo "Перезагрузка systemd..."
systemctl daemon-reload

# Настраиваем firewall
echo "Настройка firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 54321/tcp
    ufw allow 443/tcp
    ufw allow 80/tcp
    echo "Firewall настроен"
fi

# Запускаем сервис
echo "Запуск сервиса..."
systemctl start x-ui
systemctl enable x-ui

# Проверяем статус
echo "Проверка статуса сервисов..."
systemctl status mysql --no-pager -l
systemctl status x-ui --no-pager -l

echo "=== Установка завершена ==="
echo ""
echo "=== Информация о системе ==="
echo "MySQL:"
echo "  - Хост: localhost"
echo "  - Порт: 3306"
echo "  - Пользователь: root"
echo "  - Пароль: frif2003"
echo "  - База данных: 3x-ui"
echo ""
echo "3x-ui Panel:"
echo "  - URL: http://$(hostname -I | awk '{print $1}'):54321"
echo "  - Логин: admin"
echo "  - Пароль: admin"
echo ""
echo "=== Команды управления ==="
echo "Статус сервиса: sudo systemctl status x-ui"
echo "Логи сервиса: sudo journalctl -u x-ui -f"
echo "Перезапуск: sudo systemctl restart x-ui"
echo "Остановка: sudo systemctl stop x-ui"
echo ""
echo "=== Резервное копирование ==="
echo "Экспорт БД: mysqldump -u root -p 3x-ui > backup.sql"
echo "Импорт БД: mysql -u root -p 3x-ui < backup.sql"
echo ""
echo "=== Устранение неполадок ==="
echo "Проверка MySQL: sudo systemctl status mysql"
echo "Проверка подключения: mysql -u root -p -h localhost"
echo "Просмотр логов MySQL: sudo tail -f /var/log/mysql/error.log" 