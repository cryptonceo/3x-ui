#!/bin/bash

# Универсальный скрипт установки 3x-ui MySQL Edition
# Автор: AI Assistant
# Версия: 2.6.1

set -e

# Цвета для вывода
red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

# Конфигурация
VERSION="v2.6.1"
GITHUB_REPO="cryptonceo/3x-ui"
INSTALL_DIR="/usr/local/x-ui"
SERVICE_NAME="x-ui"
MYSQL_DB="3x-ui"
MYSQL_USER="root"
MYSQL_PASSWORD="frif2003"

echo -e "${blue}=== Установка 3x-ui MySQL Edition ${VERSION} ===${plain}"

# Проверяем права root
if [[ $EUID -ne 0 ]]; then
    echo -e "${red}Ошибка: Этот скрипт должен быть запущен с правами root${plain}"
    exit 1
fi

# Определяем архитектуру
arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${red}Неподдерживаемая архитектура CPU!${plain}" && exit 1 ;;
    esac
}

ARCH=$(arch)
echo -e "${green}Архитектура: ${ARCH}${plain}"

# Проверяем версию GLIBC
check_glibc_version() {
    glibc_version=$(ldd --version | head -n1 | awk '{print $NF}')
    required_version="2.32"
    
    if [[ "$(printf '%s\n' "$required_version" "$glibc_version" | sort -V | head -n1)" != "$required_version" ]]; then
        echo -e "${red}GLIBC версия $glibc_version слишком старая! Требуется: 2.32 или выше${plain}"
        exit 1
    fi
    echo -e "${green}GLIBC версия: $glibc_version (соответствует требованиям)${plain}"
}

check_glibc_version

# Определяем ОС
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo -e "${red}Не удалось определить ОС${plain}"
    exit 1
fi

echo -e "${green}ОС: $release${plain}"

# Устанавливаем базовые пакеты
install_base_packages() {
    echo -e "${blue}Установка базовых пакетов...${plain}"
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -y -q wget curl tar tzdata
        ;;
    centos | rhel | almalinux | rocky | ol)
        yum -y update && yum install -y -q wget curl tar tzdata
        ;;
    fedora | amzn | virtuozzo)
        dnf -y update && dnf install -y -q wget curl tar tzdata
        ;;
    arch | manjaro | parch)
        pacman -Syu && pacman -Syu --noconfirm wget curl tar tzdata
        ;;
    opensuse-tumbleweed)
        zypper refresh && zypper -q install -y wget curl tar timezone
        ;;
    *)
        apt-get update && apt install -y -q wget curl tar tzdata
        ;;
    esac
}

install_base_packages

# Устанавливаем MySQL
install_mysql() {
    echo -e "${blue}Установка MySQL...${plain}"
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get install -y mysql-server
        ;;
    centos | rhel | almalinux | rocky | ol)
        yum install -y mysql-server
        ;;
    fedora | amzn | virtuozzo)
        dnf install -y mysql-server
        ;;
    arch | manjaro | parch)
        pacman -Syu --noconfirm mysql
        ;;
    opensuse-tumbleweed)
        zypper install -y mysql
        ;;
    *)
        apt-get install -y mysql-server
        ;;
    esac

    # Запускаем MySQL
    systemctl start mysql
    systemctl enable mysql

    # Настраиваем MySQL
    echo -e "${blue}Настройка MySQL...${plain}"
    mysql -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mysql -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"
    mysql -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DB}\`.* TO '${MYSQL_USER}'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
}

install_mysql

# Генерируем случайные строки
gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

# Скачиваем и устанавливаем x-ui
install_x-ui() {
    echo -e "${blue}Скачивание x-ui ${VERSION}...${plain}"
    cd /usr/local/

    # Скачиваем релиз
    wget -N -O /usr/local/x-ui-linux-${ARCH}.tar.gz https://github.com/${GITHUB_REPO}/releases/download/${VERSION}/x-ui-linux-${ARCH}.tar.gz
    
    if [[ $? -ne 0 ]]; then
        echo -e "${red}Ошибка скачивания x-ui, проверьте доступ к GitHub${plain}"
        exit 1
    fi

    # Останавливаем существующий сервис
    if [[ -e /usr/local/x-ui/ ]]; then
        systemctl stop x-ui 2>/dev/null || true
        rm /usr/local/x-ui/ -rf
    fi

    # Распаковываем
    echo -e "${blue}Распаковка...${plain}"
    tar zxvf x-ui-linux-${ARCH}.tar.gz
    rm x-ui-linux-${ARCH}.tar.gz -f
    cd x-ui
    chmod +x x-ui

    # Переименовываем xray для ARM архитектур
    if [[ ${ARCH} == "armv5" || ${ARCH} == "armv6" || ${ARCH} == "armv7" ]]; then
        mv bin/xray-linux-${ARCH} bin/xray-linux-arm
        chmod +x bin/xray-linux-arm
    fi

    chmod +x x-ui bin/xray-linux-${ARCH}
    
    # Копируем systemd сервис
    cp -f x-ui.service /etc/systemd/system/
    
    # Скачиваем скрипт управления
    wget -O /usr/bin/x-ui https://raw.githubusercontent.com/${GITHUB_REPO}/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
}

install_x-ui

# Настраиваем после установки
config_after_install() {
    echo -e "${blue}Настройка конфигурации...${plain}"
    
    local existing_hasDefaultCredential=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'hasDefaultCredential: .+' | awk '{print $2}' 2>/dev/null || echo "true")
    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}' 2>/dev/null || echo "")
    local existing_port=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'port: .+' | awk '{print $2}' 2>/dev/null || echo "54321")
    local server_ip=$(curl -s https://api.ipify.org 2>/dev/null || echo "localhost")

    if [[ ${#existing_webBasePath} -lt 4 ]]; then
        if [[ "$existing_hasDefaultCredential" == "true" ]]; then
            local config_webBasePath=$(gen_random_string 15)
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            read -rp "Хотите настроить порт панели? (если нет, будет применен случайный порт) [y/n]: " config_confirm
            if [[ "${config_confirm}" == "y" || "${config_confirm}" == "Y" ]]; then
                read -rp "Укажите порт панели: " config_port
                echo -e "${yellow}Порт панели: ${config_port}${plain}"
            else
                local config_port=$(shuf -i 1024-62000 -n 1)
                echo -e "${yellow}Сгенерирован случайный порт: ${config_port}${plain}"
            fi

            /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}" -port "${config_port}" -webBasePath "${config_webBasePath}"
            echo -e "${green}Это свежая установка, генерируем случайные данные для входа:${plain}"
            echo -e "###############################################"
            echo -e "${green}Имя пользователя: ${config_username}${plain}"
            echo -e "${green}Пароль: ${config_password}${plain}"
            echo -e "${green}Порт: ${config_port}${plain}"
            echo -e "${green}WebBasePath: ${config_webBasePath}${plain}"
            echo -e "${green}URL доступа: http://${server_ip}:${config_port}/${config_webBasePath}${plain}"
            echo -e "###############################################"
        else
            local config_webBasePath=$(gen_random_string 15)
            echo -e "${yellow}WebBasePath отсутствует или слишком короткий. Генерируем новый...${plain}"
            /usr/local/x-ui/x-ui setting -webBasePath "${config_webBasePath}"
            echo -e "${green}Новый WebBasePath: ${config_webBasePath}${plain}"
            echo -e "${green}URL доступа: http://${server_ip}:${existing_port}/${config_webBasePath}${plain}"
        fi
    else
        if [[ "$existing_hasDefaultCredential" == "true" ]]; then
            local config_username=$(gen_random_string 10)
            local config_password=$(gen_random_string 10)

            echo -e "${yellow}Обнаружены стандартные учетные данные. Требуется обновление безопасности...${plain}"
            /usr/local/x-ui/x-ui setting -username "${config_username}" -password "${config_password}"
            echo -e "${green}Сгенерированы новые случайные учетные данные:${plain}"
            echo -e "###############################################"
            echo -e "${green}Имя пользователя: ${config_username}${plain}"
            echo -e "${green}Пароль: ${config_password}${plain}"
            echo -e "###############################################"
        else
            echo -e "${green}Имя пользователя, пароль и WebBasePath правильно настроены.${plain}"
        fi
    fi

    # Запускаем миграцию
    /usr/local/x-ui/x-ui migrate
}

    config_after_install

# Настраиваем systemd
echo -e "${blue}Настройка systemd...${plain}"
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui

# Настраиваем firewall
echo -e "${blue}Настройка firewall...${plain}"
if command -v ufw &> /dev/null; then
    ufw allow 54321/tcp
    echo -e "${green}Firewall настроен${plain}"
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=54321/tcp
    firewall-cmd --reload
    echo -e "${green}Firewall настроен${plain}"
fi

# Получаем IP адрес
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")

# Проверяем статус
echo -e "${blue}Проверка статуса...${plain}"
sleep 5
systemctl status x-ui --no-pager -l

echo ""
echo -e "${green}=== Установка завершена ===${plain}"
echo ""
echo -e "${blue}Информация о системе:${plain}"
echo -e "  MySQL:"
echo -e "    - Хост: localhost"
echo -e "    - Порт: 3306"
echo -e "    - Пользователь: ${MYSQL_USER}"
echo -e "    - Пароль: ${MYSQL_PASSWORD}"
echo -e "    - База данных: ${MYSQL_DB}"
echo ""
echo -e "  3x-ui Panel:"
echo -e "    - URL: http://${SERVER_IP}:54321"
echo -e "    - Версия: ${VERSION}"
echo ""
echo -e "${blue}Управление сервисом:${plain}"
echo -e "    - Статус: sudo systemctl status x-ui"
echo -e "    - Логи: sudo journalctl -u x-ui -f"
echo -e "    - Перезапуск: sudo systemctl restart x-ui"
echo -e "    - Остановка: sudo systemctl stop x-ui"
echo ""
echo -e "${blue}Резервное копирование:${plain}"
echo -e "    - Экспорт БД: mysqldump -u ${MYSQL_USER} -p ${MYSQL_DB} > backup.sql"
echo -e "    - Импорт БД: mysql -u ${MYSQL_USER} -p ${MYSQL_DB} < backup.sql"
echo ""
echo -e "${green}x-ui ${VERSION} установка завершена, сервис запущен!${plain}"
echo -e ""
echo -e "┌───────────────────────────────────────────────────────┐"
echo -e "│  ${blue}Использование команды x-ui (подкоманды):${plain}              │"
echo -e "│                                                       │"
echo -e "│  ${blue}x-ui${plain}              - Скрипт управления администратора    │"
echo -e "│  ${blue}x-ui start${plain}        - Запуск                              │"
echo -e "│  ${blue}x-ui stop${plain}         - Остановка                           │"
echo -e "│  ${blue}x-ui restart${plain}      - Перезапуск                          │"
echo -e "│  ${blue}x-ui status${plain}       - Текущий статус                      │"
echo -e "│  ${blue}x-ui settings${plain}     - Текущие настройки                   │"
echo -e "│  ${blue}x-ui enable${plain}       - Включить автозапуск при старте ОС   │"
echo -e "│  ${blue}x-ui disable${plain}      - Отключить автозапуск при старте ОС  │"
echo -e "│  ${blue}x-ui log${plain}          - Просмотр логов                       │"
echo -e "│  ${blue}x-ui banlog${plain}       - Просмотр логов блокировок Fail2ban  │"
echo -e "│  ${blue}x-ui update${plain}       - Обновление                           │"
echo -e "│  ${blue}x-ui legacy${plain}       - Устаревшая версия                    │"
echo -e "│  ${blue}x-ui install${plain}      - Установка                            │"
echo -e "│  ${blue}x-ui uninstall${plain}    - Удаление                             │"
echo -e "└───────────────────────────────────────────────────────┘"
echo ""
echo -e "${green}Установка успешно завершена!${plain}"
