#!/bin/bash

# Скрипт для установки и настройки MySQL для 3x-ui
# Автор: AI Assistant
# Версия: 1.0

set -e

echo "=== Установка и настройка MySQL для 3x-ui ==="

# Проверяем, что мы на Ubuntu/Debian
if ! command -v apt-get &> /dev/null; then
    echo "Ошибка: Этот скрипт предназначен для Ubuntu/Debian систем"
    exit 1
fi

# Обновляем пакеты
echo "Обновление пакетов..."
sudo apt-get update

# Устанавливаем MySQL Server
echo "Установка MySQL Server..."
sudo apt-get install -y mysql-server

# Запускаем MySQL сервис
echo "Запуск MySQL сервиса..."
sudo systemctl start mysql
sudo systemctl enable mysql

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
sudo mysql < /tmp/mysql_setup.sql

# Удаляем временный файл
rm /tmp/mysql_setup.sql

echo "=== MySQL успешно установлен и настроен ==="
echo "База данных: 3x-ui"
echo "Пользователь: root"
echo "Пароль: frif2003"
echo "Хост: localhost"
echo "Порт: 3306"

# Проверяем статус MySQL
echo "Проверка статуса MySQL..."
sudo systemctl status mysql --no-pager -l

echo "=== Установка завершена ===" 