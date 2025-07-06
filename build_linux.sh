#!/bin/bash

# Скрипт для сборки 3x-ui под Linux Ubuntu
# Автор: AI Assistant
# Версия: 1.0

set -e

echo "=== Сборка 3x-ui для Linux Ubuntu ==="

# Проверяем наличие Go
if ! command -v go &> /dev/null; then
    echo "Установка Go..."
    wget https://go.dev/dl/go1.24.4.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.24.4.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    source ~/.bashrc
    rm go1.24.4.linux-amd64.tar.gz
fi

# Проверяем версию Go
echo "Версия Go:"
go version

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
sudo tee /etc/systemd/system/x-ui.service > /dev/null << EOF
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

[Install]
WantedBy=multi-user.target
EOF

# Создаем директорию для установки
echo "Создание директории установки..."
sudo mkdir -p /usr/local/x-ui

# Копируем файлы
echo "Копирование файлов..."
sudo cp x-ui /usr/local/x-ui/
sudo cp -r web /usr/local/x-ui/
sudo cp -r config /usr/local/x-ui/
sudo cp -r database /usr/local/x-ui/
sudo cp -r logger /usr/local/x-ui/
sudo cp -r sub /usr/local/x-ui/
sudo cp -r util /usr/local/x-ui/
sudo cp -r xray /usr/local/x-ui/

# Устанавливаем права
echo "Установка прав доступа..."
sudo chmod +x /usr/local/x-ui/x-ui
sudo chown -R root:root /usr/local/x-ui

# Перезагружаем systemd
echo "Перезагрузка systemd..."
sudo systemctl daemon-reload

echo "=== Установка завершена ==="
echo "Для запуска сервиса выполните:"
echo "sudo systemctl start x-ui"
echo "sudo systemctl enable x-ui"
echo ""
echo "Для просмотра статуса:"
echo "sudo systemctl status x-ui"
echo ""
echo "Для просмотра логов:"
echo "sudo journalctl -u x-ui -f" 