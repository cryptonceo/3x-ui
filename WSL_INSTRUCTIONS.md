# Инструкция по настройке SSH в WSL

## Шаг 1: Откройте WSL терминал

В Windows откройте PowerShell или Command Prompt и выполните:
```bash
wsl
```

## Шаг 2: Выполните скрипт очистки

```bash
# Делаем скрипт исполняемым
chmod +x wsl_cleanup.sh

# Запускаем скрипт
sudo ./wsl_cleanup.sh
```

## Шаг 3: Альтернативный способ (если скрипт не работает)

### Удаление 3x-ui
```bash
# Останавливаем сервисы
sudo systemctl stop x-ui 2>/dev/null || true
sudo systemctl stop mysql 2>/dev/null || true

# Удаляем файлы
sudo rm -rf /usr/local/x-ui
sudo rm -rf /var/log/x-ui
sudo rm -f /etc/systemd/system/x-ui.service

# Удаляем из домашней директории
rm -rf ~/x-ui
rm -rf ~/3x-ui*
```

### Установка SSH
```bash
# Обновляем пакеты
sudo apt-get update

# Устанавливаем SSH сервер
sudo apt-get install -y openssh-server

# Создаем пользователя admin
sudo useradd -m -s /bin/bash admin
echo "admin:admin123" | sudo chpasswd
sudo usermod -aG sudo admin

# Настраиваем SSH
sudo mkdir -p /home/admin/.ssh
sudo chmod 700 /home/admin/.ssh

# Генерируем SSH ключи
sudo -u admin ssh-keygen -t rsa -b 4096 -f /home/admin/.ssh/id_rsa -N ""

# Настраиваем authorized_keys
sudo cp /home/admin/.ssh/id_rsa.pub /home/admin/.ssh/authorized_keys
sudo chmod 600 /home/admin/.ssh/authorized_keys
sudo chown -R admin:admin /home/admin/.ssh

# Запускаем SSH
sudo service ssh start
sudo systemctl enable ssh
```

## Шаг 4: Получение IP адреса

```bash
# Получаем IP адрес WSL
hostname -I
```

## Шаг 5: Настройка Windows Firewall

В Windows PowerShell (от администратора):
```powershell
# Разрешаем SSH порт
netsh advfirewall firewall add rule name="WSL SSH" dir=in action=allow protocol=TCP localport=22
```

## Шаг 6: Подключение через Termius

### Информация для подключения:
- **Хост**: IP адрес из команды `hostname -I`
- **Порт**: 22
- **Пользователь**: admin
- **Пароль**: admin123

### Шаги в Termius:
1. Откройте Termius
2. Нажмите "+" для добавления нового хоста
3. Введите IP адрес WSL
4. Порт: 22
5. Пользователь: admin
6. Пароль: admin123
7. Сохраните подключение

## Шаг 7: Проверка подключения

```bash
# Проверяем статус SSH
sudo service ssh status

# Проверяем SSH ключи
sudo cat /home/admin/.ssh/id_rsa
sudo cat /home/admin/.ssh/id_rsa.pub
```

## Возможные проблемы и решения

### Проблема 1: SSH не запускается
```bash
# Перезапускаем SSH
sudo service ssh restart

# Проверяем логи
sudo tail -f /var/log/auth.log
```

### Проблема 2: Не удается подключиться
```bash
# Проверяем, что SSH слушает порт 22
sudo netstat -tlnp | grep :22

# Проверяем firewall
sudo ufw status
```

### Проблема 3: WSL IP изменился
```bash
# Получаем новый IP
hostname -I

# Или используйте localhost
# В Termius используйте: 127.0.0.1
```

## Дополнительные настройки

### Настройка статического IP (опционально)
```bash
# Редактируем конфигурацию сети
sudo nano /etc/netplan/01-wsl.yaml

# Добавляем статический IP
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

# Применяем конфигурацию
sudo netplan apply
```

### Настройка SSH ключей для безопасного подключения
```bash
# Создаем новый ключ на клиенте
ssh-keygen -t rsa -b 4096

# Копируем публичный ключ на сервер
ssh-copy-id admin@WSL_IP

# Отключаем парольную аутентификацию (опционально)
sudo nano /etc/ssh/sshd_config
# Измените: PasswordAuthentication no
sudo service ssh restart
```

## Команды для управления

```bash
# Остановка SSH
sudo service ssh stop

# Запуск SSH
sudo service ssh start

# Перезапуск SSH
sudo service ssh restart

# Проверка статуса
sudo service ssh status

# Просмотр логов
sudo tail -f /var/log/auth.log
```

## Безопасность

### Рекомендации:
1. Измените пароль по умолчанию
2. Используйте SSH ключи вместо паролей
3. Отключите root логин
4. Измените порт SSH (опционально)
5. Настройте fail2ban для защиты от брутфорса

### Изменение пароля:
```bash
sudo passwd admin
```

### Настройка fail2ban:
```bash
sudo apt-get install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
``` 