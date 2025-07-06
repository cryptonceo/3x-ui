# Финальная инструкция по настройке SSH в WSL

## 🚀 Быстрый старт

### Шаг 1: Откройте WSL
В Windows PowerShell или Command Prompt:
```bash
wsl
```

### Шаг 2: Выполните скрипт
```bash
# Делаем скрипт исполняемым
chmod +x quick_ssh_setup.sh

# Запускаем скрипт
sudo ./quick_ssh_setup.sh
```

### Шаг 3: Настройте Windows Firewall
В Windows PowerShell (от администратора):
```powershell
netsh advfirewall firewall add rule name="WSL SSH" dir=in action=allow protocol=TCP localport=22
```

### Шаг 4: Подключитесь через Termius

1. **Откройте Termius**
2. **Нажмите "+" для добавления нового хоста**
3. **Введите данные:**
   - **Хост**: IP адрес из вывода скрипта
   - **Порт**: 22
   - **Пользователь**: admin
   - **Пароль**: admin123

## 📋 Подробная инструкция

### Если скрипт не работает, выполните команды вручную:

```bash
# 1. Удаляем 3x-ui
sudo systemctl stop x-ui 2>/dev/null || true
sudo systemctl stop mysql 2>/dev/null || true
sudo rm -rf /usr/local/x-ui
sudo rm -rf /var/log/x-ui
sudo rm -f /etc/systemd/system/x-ui.service
rm -rf ~/x-ui
rm -rf ~/3x-ui*

# 2. Устанавливаем SSH
sudo apt-get update
sudo apt-get install -y openssh-server

# 3. Создаем пользователя
sudo useradd -m -s /bin/bash admin
echo "admin:admin123" | sudo chpasswd
sudo usermod -aG sudo admin

# 4. Настраиваем SSH
sudo mkdir -p /home/admin/.ssh
sudo chmod 700 /home/admin/.ssh
sudo -u admin ssh-keygen -t rsa -b 4096 -f /home/admin/.ssh/id_rsa -N ""
sudo cp /home/admin/.ssh/id_rsa.pub /home/admin/.ssh/authorized_keys
sudo chmod 600 /home/admin/.ssh/authorized_keys
sudo chown -R admin:admin /home/admin/.ssh

# 5. Запускаем SSH
sudo service ssh start
sudo systemctl enable ssh

# 6. Получаем IP
hostname -I
```

## 🔧 Проверка подключения

### Проверьте статус SSH:
```bash
sudo service ssh status
```

### Проверьте, что SSH слушает порт 22:
```bash
sudo netstat -tlnp | grep :22
```

### Проверьте SSH ключи:
```bash
sudo cat /home/admin/.ssh/id_rsa
sudo cat /home/admin/.ssh/id_rsa.pub
```

## 🌐 Подключение через Termius

### Информация для подключения:
- **Хост**: IP адрес из команды `hostname -I`
- **Порт**: 22
- **Пользователь**: admin
- **Пароль**: admin123

### Пошаговая инструкция для Termius:

1. **Откройте приложение Termius**
2. **Нажмите кнопку "+" (добавить новый хост)**
3. **Заполните поля:**
   - **Hostname**: IP адрес WSL
   - **Port**: 22
   - **Username**: admin
   - **Password**: admin123
4. **Нажмите "Save"**
5. **Нажмите на созданное подключение для подключения**

## 🔒 Безопасность

### Рекомендуемые настройки безопасности:

1. **Измените пароль по умолчанию:**
```bash
sudo passwd admin
```

2. **Используйте SSH ключи вместо паролей:**
```bash
# На клиенте создайте ключ
ssh-keygen -t rsa -b 4096

# Скопируйте ключ на сервер
ssh-copy-id admin@WSL_IP
```

3. **Отключите парольную аутентификацию:**
```bash
sudo nano /etc/ssh/sshd_config
# Измените: PasswordAuthentication no
sudo service ssh restart
```

## 🚨 Устранение неполадок

### Проблема 1: Не удается подключиться
```bash
# Проверьте статус SSH
sudo service ssh status

# Перезапустите SSH
sudo service ssh restart

# Проверьте логи
sudo tail -f /var/log/auth.log
```

### Проблема 2: SSH не запускается
```bash
# Проверьте конфигурацию
sudo sshd -t

# Переустановите SSH
sudo apt-get remove --purge openssh-server
sudo apt-get install openssh-server
```

### Проблема 3: WSL IP изменился
```bash
# Получите новый IP
hostname -I

# Или используйте localhost в Termius: 127.0.0.1
```

### Проблема 4: Firewall блокирует подключение
В Windows PowerShell (от администратора):
```powershell
# Разрешите порт 22
netsh advfirewall firewall add rule name="WSL SSH" dir=in action=allow protocol=TCP localport=22

# Или отключите firewall временно
netsh advfirewall set allprofiles state off
```

## 📱 Использование в Termius

### Основные команды:
- **Подключение**: Нажмите на хост в списке
- **Отключение**: Введите `exit` или нажмите Ctrl+D
- **Новая сессия**: Нажмите "+" в терминале
- **Копирование**: Выделите текст и нажмите "Copy"
- **Вставка**: Долгое нажатие в терминале

### Полезные команды в SSH:
```bash
# Обновление системы
sudo apt-get update && sudo apt-get upgrade -y

# Просмотр информации о системе
htop
df -h
free -h

# Управление сервисами
sudo systemctl status ssh
sudo service ssh restart
```

## 🎯 Готово!

После выполнения всех шагов у вас будет:
- ✅ Удален 3x-ui
- ✅ Настроен SSH сервер
- ✅ Создан пользователь admin
- ✅ Настроены SSH ключи
- ✅ Готово для подключения через Termius

### Для подключения используйте:
- **Хост**: IP адрес WSL
- **Порт**: 22
- **Пользователь**: admin
- **Пароль**: admin123 