#!/bin/bash

# Быстрый скрипт установки 3x-ui MySQL Edition
# Автор: AI Assistant
# Версия: 2.6.1

set -e

# Цвета для вывода
red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
yellow='\033[0;33m'
plain='\033[0m'

echo -e "${blue}=== Быстрая установка 3x-ui MySQL Edition ===${plain}"

# Проверяем права root
if [[ $EUID -ne 0 ]]; then
    echo -e "${red}Ошибка: Этот скрипт должен быть запущен с правами root${plain}"
    echo -e "${yellow}Используйте: sudo bash quick_install.sh${plain}"
    exit 1
fi

# Проверяем наличие curl
if ! command -v curl &> /dev/null; then
    echo -e "${blue}Установка curl...${plain}"
    apt-get update && apt-get install -y curl
fi

# Скачиваем основной скрипт установки
echo -e "${blue}Скачивание скрипта установки...${plain}"
curl -fsSL https://raw.githubusercontent.com/cryptonceo/3x-ui/main/install.sh -o /tmp/install.sh

if [[ $? -ne 0 ]]; then
    echo -e "${red}Ошибка скачивания скрипта установки${plain}"
    exit 1
fi

# Делаем скрипт исполняемым
chmod +x /tmp/install.sh

# Запускаем установку
echo -e "${green}Запуск установки...${plain}"
bash /tmp/install.sh

# Очищаем временные файлы
rm -f /tmp/install.sh

echo -e "${green}Быстрая установка завершена!${plain}" 