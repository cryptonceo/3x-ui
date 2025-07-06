#!/bin/bash

# Упрощенный скрипт для очистки в WSL
# Автор: AI Assistant

echo "=== Очистка 3x-ui в WSL ==="

# Удаляем файлы 3x-ui
echo "Удаление файлов 3x-ui..."
rm -rf /usr/local/x-ui 2>/dev/null || true
rm -rf /var/log/x-ui 2>/dev/null || true
rm -f /etc/systemd/system/x-ui.service 2>/dev/null || true

# Удаляем текущие файлы в домашней директории
echo "Удаление файлов в домашней директории..."
rm -rf ~/x-ui 2>/dev/null || true
rm -rf ~/3x-ui* 2>/dev/null || true

# Устанавливаем SSH сервер
echo "Установка SSH сервера..."
sudo apt-get update
sudo apt-get install -y openssh-server

# Создаем нового пользователя
echo "Создание нового пользователя..."
NEW_USER="empty"
PASSWORD="frif2003"

# Создаем пользователя если не существует
if ! id "$NEW_USER" &>/dev/null; then
    sudo useradd -m -s /bin/bash $NEW_USER
    echo "$NEW_USER:$PASSWORD" | sudo chpasswd
    sudo usermod -aG sudo $NEW_USER
fi

# Настраиваем SSH
echo "Настройка SSH..."
sudo mkdir -p /etc/ssh
sudo tee /etc/ssh/sshd_config > /dev/null << EOF
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
UsePrivilegeSeparation yes
KeyRegenerationInterval 3600
ServerKeyBits 1024
SyslogFacility AUTH
LogLevel INFO
LoginGraceTime 120
PermitRootLogin no
StrictModes yes
RSAAuthentication yes
PubkeyAuthentication yes
AuthorizedKeysFile %h/.ssh/authorized_keys
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
PasswordAuthentication yes
X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
UsePAM yes
EOF

# Создаем SSH директорию для нового пользователя
sudo mkdir -p /home/$NEW_USER/.ssh
sudo chmod 700 /home/$NEW_USER/.ssh

# Генерируем SSH ключи для нового пользователя
echo "Генерация SSH ключей..."
sudo -u $NEW_USER ssh-keygen -t rsa -b 4096 -f /home/$NEW_USER/.ssh/id_rsa -N ""

# Копируем публичный ключ в authorized_keys
sudo cp /home/$NEW_USER/.ssh/id_rsa.pub /home/$NEW_USER/.ssh/authorized_keys
sudo chmod 600 /home/$NEW_USER/.ssh/authorized_keys
sudo chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh

# Запускаем SSH сервис
echo "Запуск SSH сервиса..."
sudo service ssh start
sudo systemctl enable ssh

# Получаем IP адрес WSL
WSL_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "=== Настройка завершена ==="
echo ""
echo "Информация для подключения через Termius:"
echo "  Хост: $WSL_IP"
echo "  Порт: 22"
echo "  Пользователь: $NEW_USER"
echo "  Пароль: $PASSWORD"
echo ""
echo "SSH ключ (приватный):"
echo "---"
sudo cat /home/$NEW_USER/.ssh/id_rsa
echo "---"
echo ""
echo "SSH ключ (публичный):"
echo "---"
sudo cat /home/$NEW_USER/.ssh/id_rsa.pub
echo "---"
echo ""
echo "Для подключения через Termius:"
echo "1. Откройте Termius"
echo "2. Нажмите '+' для добавления нового хоста"
echo "3. Введите IP адрес: $WSL_IP"
echo "4. Порт: 22"
echo "5. Пользователь: $NEW_USER"
echo "6. Пароль: $PASSWORD"
echo "7. Или используйте SSH ключ"
echo ""
echo "Проверка SSH статуса:"
sudo service ssh status 