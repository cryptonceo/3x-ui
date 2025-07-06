#!/bin/bash

# Скрипт для очистки 3x-ui и настройки SSH доступа
# Автор: AI Assistant
# Версия: 1.0

set -e

echo "=== Очистка 3x-ui и настройка SSH ==="

# Останавливаем сервисы
echo "Остановка сервисов..."
if systemctl is-active --quiet x-ui; then
    systemctl stop x-ui
    systemctl disable x-ui
fi

if systemctl is-active --quiet mysql; then
    systemctl stop mysql
    systemctl disable mysql
fi

# Удаляем файлы 3x-ui
echo "Удаление файлов 3x-ui..."
rm -rf /usr/local/x-ui
rm -rf /var/log/x-ui
rm -f /etc/systemd/system/x-ui.service

# Удаляем базу данных MySQL
echo "Удаление базы данных MySQL..."
mysql -u root -p -e "DROP DATABASE IF EXISTS \`3x-ui\`;"

# Перезагружаем systemd
systemctl daemon-reload

# Устанавливаем SSH сервер
echo "Установка SSH сервера..."
apt-get update
apt-get install -y openssh-server

# Настраиваем SSH
echo "Настройка SSH..."
mkdir -p /etc/ssh
cat > /etc/ssh/sshd_config << EOF
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

# Создаем нового пользователя
echo "Создание нового пользователя..."
NEW_USER="empty"
PASSWORD="frif2003"

# Создаем пользователя
useradd -m -s /bin/bash $NEW_USER
echo "$NEW_USER:$PASSWORD" | chpasswd

# Добавляем пользователя в sudo группу
usermod -aG sudo $NEW_USER

# Создаем SSH директорию для нового пользователя
mkdir -p /home/$NEW_USER/.ssh
chmod 700 /home/$NEW_USER/.ssh

# Генерируем SSH ключи для нового пользователя
echo "Генерация SSH ключей..."
sudo -u $NEW_USER ssh-keygen -t rsa -b 4096 -f /home/$NEW_USER/.ssh/id_rsa -N ""

# Копируем публичный ключ в authorized_keys
cp /home/$NEW_USER/.ssh/id_rsa.pub /home/$NEW_USER/.ssh/authorized_keys
chmod 600 /home/$NEW_USER/.ssh/authorized_keys
chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh

# Запускаем SSH сервис
echo "Запуск SSH сервиса..."
systemctl start ssh
systemctl enable ssh

# Показываем информацию для подключения
echo ""
echo "=== Настройка завершена ==="
echo ""
echo "Информация для подключения через Termius:"
echo "  Хост: $(hostname -I | awk '{print $1}')"
echo "  Порт: 22"
echo "  Пользователь: $NEW_USER"
echo "  Пароль: $PASSWORD"
echo ""
echo "SSH ключ (приватный):"
echo "---"
cat /home/$NEW_USER/.ssh/id_rsa
echo "---"
echo ""
echo "SSH ключ (публичный):"
echo "---"
cat /home/$NEW_USER/.ssh/id_rsa.pub
echo "---"
echo ""
echo "Для подключения через Termius:"
echo "1. Откройте Termius"
echo "2. Нажмите '+' для добавления нового хоста"
echo "3. Введите IP адрес: $(hostname -I | awk '{print $1}')"
echo "4. Порт: 22"
echo "5. Пользователь: $NEW_USER"
echo "6. Пароль: $PASSWORD"
echo "7. Или используйте SSH ключ"
echo ""
echo "Проверка SSH статуса:"
systemctl status ssh --no-pager -l 