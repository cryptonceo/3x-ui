#!/bin/bash

# Быстрый скрипт для настройки SSH в WSL
echo "=== Быстрая настройка SSH в WSL ==="

# Удаляем 3x-ui
echo "Удаление 3x-ui..."
sudo systemctl stop x-ui 2>/dev/null || true
sudo systemctl stop mysql 2>/dev/null || true
sudo rm -rf /usr/local/x-ui
sudo rm -rf /var/log/x-ui
sudo rm -f /etc/systemd/system/x-ui.service
rm -rf ~/x-ui
rm -rf ~/3x-ui*

# Устанавливаем SSH
echo "Установка SSH..."
sudo apt-get update
sudo apt-get install -y openssh-server

# Создаем пользователя
echo "Создание пользователя empty..."
sudo useradd -m -s /bin/bash empty 2>/dev/null || true
echo "empty:empty123" | sudo chpasswd
sudo usermod -aG sudo empty

# Настраиваем SSH
echo "Настройка SSH..."
sudo mkdir -p /home/empty/.ssh
sudo chmod 700 /home/empty/.ssh

# Генерируем ключи
echo "Генерация SSH ключей..."
sudo -u empty ssh-keygen -t rsa -b 4096 -f /home/empty/.ssh/id_rsa -N ""
sudo cp /home/empty/.ssh/id_rsa.pub /home/empty/.ssh/authorized_keys
sudo chmod 600 /home/empty/.ssh/authorized_keys
sudo chown -R empty:empty /home/empty/.ssh

# Запускаем SSH
echo "Запуск SSH..."
sudo service ssh start
sudo systemctl enable ssh

# Получаем IP
WSL_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "=== Настройка завершена ==="
echo ""
echo "Информация для Termius:"
echo "  Хост: $WSL_IP"
echo "  Порт: 22"
echo "  Пользователь: empty"
echo "  Пароль: frif2003"
echo ""
echo "SSH ключ (приватный):"
echo "---"
sudo cat /home/empty/.ssh/id_rsa
echo "---"
echo ""
echo "SSH ключ (публичный):"
echo "---"
sudo cat /home/empty/.ssh/id_rsa.pub
echo "---"
echo ""
echo "Статус SSH:"
sudo service ssh status 