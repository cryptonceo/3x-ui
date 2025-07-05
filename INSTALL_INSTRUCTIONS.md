# Установка x-ui с MySQL через curl

## Быстрая установка

Для установки x-ui с поддержкой MySQL используйте следующую команду:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/your-username/x-ui/master/install_mysql.sh)
```

## Что делает скрипт

1. **Проверяет права root** - скрипт должен запускаться с правами администратора
2. **Определяет ОС** - автоматически определяет Ubuntu, Debian, CentOS, Rocky Linux
3. **Устанавливает зависимости** - MySQL, Go, firewall, fail2ban
4. **Настраивает MySQL** - создает базу данных и пользователя для x-ui
5. **Скачивает и собирает x-ui** - клонирует репозиторий и собирает бинарный файл
6. **Устанавливает x-ui** - копирует файлы в `/usr/local/x-ui`
7. **Настраивает systemd** - создает сервис с переменными окружения
8. **Настраивает firewall** - открывает необходимые порты
9. **Генерирует учетные данные** - создает случайные логин/пароль/порт

## Требования

- Linux сервер (Ubuntu 18.04+, Debian 9+, CentOS 7+)
- Права root
- Интернет соединение
- Минимум 512MB RAM
- 1GB свободного места

## Автоматическая установка

### Ubuntu/Debian
```bash
sudo bash <(curl -Ls https://raw.githubusercontent.com/your-username/x-ui/master/install_mysql.sh)
```

### CentOS/Rocky Linux
```bash
sudo bash <(curl -Ls https://raw.githubusercontent.com/your-username/x-ui/master/install_mysql.sh)
```

## Что устанавливается

### Системные пакеты
- `mariadb-server` - MySQL сервер
- `mariadb-client` - MySQL клиент
- `golang-go` - Go компилятор
- `ufw` - файрвол
- `fail2ban` - защита от брутфорса
- `git` - для скачивания исходного кода

### MySQL настройки
- База данных: `xui_db`
- Пользователь: `xui_user`
- Пароль: `xui_password`
- Хост: `localhost:3306`

### x-ui настройки
- Директория: `/usr/local/x-ui`
- Конфигурация: `/etc/x-ui/.env`
- Логи: `/var/log/x-ui`
- Сервис: `x-ui.service`

## После установки

### Проверка статуса
```bash
# Проверить статус сервиса
systemctl status x-ui

# Посмотреть логи
journalctl -u x-ui -f

# Проверить MySQL
systemctl status mariadb
```

### Управление x-ui
```bash
# Запустить
systemctl start x-ui

# Остановить
systemctl stop x-ui

# Перезапустить
systemctl restart x-ui

# Включить автозапуск
systemctl enable x-ui
```

### Доступ к панели
После установки скрипт покажет:
- URL для доступа к панели
- Логин и пароль
- Порт и путь

Пример:
```
Access panel: http://your-server-ip:12345/abc123def456
Login: admin123
Password: pass456
```

## Ручная установка

Если автоматическая установка не работает, можно установить вручную:

### 1. Установить зависимости
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y mariadb-server mariadb-client golang-go git ufw fail2ban

# CentOS/Rocky Linux
sudo yum install -y mariadb-server mariadb golang git firewalld fail2ban
```

### 2. Настроить MySQL
```bash
# Запустить MySQL
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Настроить безопасность
sudo mysql_secure_installation

# Создать базу данных
sudo mysql -u root -e "
CREATE DATABASE IF NOT EXISTS xui_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'xui_user'@'localhost' IDENTIFIED BY 'xui_password';
GRANT ALL PRIVILEGES ON xui_db.* TO 'xui_user'@'localhost';
FLUSH PRIVILEGES;
"
```

### 3. Скачать и собрать x-ui
```bash
# Скачать исходный код
git clone https://github.com/your-username/x-ui.git
cd x-ui

# Собрать
export GOOS=linux
export GOARCH=amd64
export CGO_ENABLED=0
go mod tidy
go build -ldflags="-s -w" -o x-ui main.go
```

### 4. Установить x-ui
```bash
# Создать директорию
sudo mkdir -p /usr/local/x-ui

# Скопировать файлы
sudo cp x-ui /usr/local/x-ui/
sudo cp -r web/ /usr/local/x-ui/
sudo cp -r config/ /usr/local/x-ui/
sudo cp -r database/ /usr/local/x-ui/
sudo cp -r logger/ /usr/local/x-ui/
sudo cp -r sub/ /usr/local/x-ui/
sudo cp -r util/ /usr/local/x-ui/
sudo cp -r xray/ /usr/local/x-ui/

# Сделать исполняемым
sudo chmod +x /usr/local/x-ui/x-ui
```

### 5. Настроить переменные окружения
```bash
# Создать конфигурацию
sudo mkdir -p /etc/x-ui
sudo tee /etc/x-ui/.env > /dev/null <<EOF
XUI_DB_TYPE=mysql
XUI_DB_DSN=xui_user:xui_password@tcp(127.0.0.1:3306)/xui_db?charset=utf8mb4&parseTime=True&loc=Local
XUI_LOG_LEVEL=info
XUI_DEBUG=false
XUI_BIN_FOLDER=/usr/local/x-ui/bin
XUI_DB_FOLDER=/etc/x-ui
XUI_LOG_FOLDER=/var/log/x-ui
EOF

sudo chmod 600 /etc/x-ui/.env
```

### 6. Настроить systemd
```bash
# Скопировать сервис файл
sudo cp x-ui.service /etc/systemd/system/

# Создать override для переменных окружения
sudo mkdir -p /etc/systemd/system/x-ui.service.d
sudo tee /etc/systemd/system/x-ui.service.d/override.conf > /dev/null <<EOF
[Service]
EnvironmentFile=/etc/x-ui/.env
EOF

# Перезагрузить systemd
sudo systemctl daemon-reload
sudo systemctl enable x-ui
```

### 7. Настроить firewall
```bash
# Ubuntu/Debian
sudo ufw allow 22/tcp
sudo ufw allow 54321/tcp
sudo ufw --force enable

# CentOS/Rocky Linux
sudo firewall-cmd --permanent --add-port=22/tcp
sudo firewall-cmd --permanent --add-port=54321/tcp
sudo firewall-cmd --reload
```

### 8. Запустить x-ui
```bash
# Запустить сервис
sudo systemctl start x-ui

# Проверить статус
sudo systemctl status x-ui
```

## Устранение неполадок

### Проблемы с MySQL
```bash
# Проверить статус MySQL
systemctl status mariadb

# Перезапустить MySQL
systemctl restart mariadb

# Проверить подключение
mysql -u xui_user -p -e "USE xui_db; SHOW TABLES;"
```

### Проблемы с x-ui
```bash
# Проверить логи
journalctl -u x-ui -f

# Проверить конфигурацию
cat /etc/x-ui/.env

# Перезапустить x-ui
systemctl restart x-ui
```

### Проблемы с firewall
```bash
# Ubuntu/Debian
sudo ufw status

# CentOS/Rocky Linux
sudo firewall-cmd --list-all
```

### Проблемы с правами
```bash
# Проверить права на файлы
ls -la /usr/local/x-ui/
ls -la /etc/x-ui/

# Исправить права
sudo chown -R root:root /usr/local/x-ui/
sudo chmod +x /usr/local/x-ui/x-ui
```

## Обновление

Для обновления x-ui:

```bash
# Остановить сервис
systemctl stop x-ui

# Скачать новую версию
cd /tmp
git clone https://github.com/your-username/x-ui.git
cd x-ui

# Собрать новую версию
export GOOS=linux
export GOARCH=amd64
export CGO_ENABLED=0
go mod tidy
go build -ldflags="-s -w" -o x-ui main.go

# Заменить старую версию
cp x-ui /usr/local/x-ui/
chmod +x /usr/local/x-ui/x-ui

# Запустить сервис
systemctl start x-ui
```

## Удаление

Для полного удаления x-ui:

```bash
# Остановить сервис
systemctl stop x-ui
systemctl disable x-ui

# Удалить файлы
rm -rf /usr/local/x-ui
rm -rf /etc/x-ui
rm /etc/systemd/system/x-ui.service
rm -rf /etc/systemd/system/x-ui.service.d

# Перезагрузить systemd
systemctl daemon-reload

# Удалить базу данных (опционально)
mysql -u root -e "DROP DATABASE IF EXISTS xui_db; DROP USER IF EXISTS 'xui_user'@'localhost';"
```

## Поддержка

- Создавайте issues в GitHub репозитории
- Проверяйте логи: `journalctl -u x-ui -f`
- Проверяйте статус MySQL: `systemctl status mariadb` 