[English](/README.md) | [فارسی](/README.fa_IR.md) | [العربية](/README.ar_EG.md) |  [中文](/README.zh_CN.md) | [Español](/README.es_ES.md) | [Русский](/README.ru_RU.md)

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="./media/3x-ui-dark.png">
    <img alt="3x-ui" src="./media/3x-ui-light.png">
  </picture>
</p>

[![](https://img.shields.io/github/v/release/mhsanaei/3x-ui.svg?style=for-the-badge)](https://github.com/MHSanaei/3x-ui/releases)
[![](https://img.shields.io/github/actions/workflow/status/mhsanaei/3x-ui/release.yml.svg?style=for-the-badge)](https://github.com/MHSanaei/3x-ui/actions)
[![GO Version](https://img.shields.io/github/go-mod/go-version/mhsanaei/3x-ui.svg?style=for-the-badge)](#)
[![Downloads](https://img.shields.io/github/downloads/mhsanaei/3x-ui/total.svg?style=for-the-badge)](https://github.com/MHSanaei/3x-ui/releases/latest)
[![License](https://img.shields.io/badge/license-GPL%20V3-blue.svg?longCache=true&style=for-the-badge)](https://www.gnu.org/licenses/gpl-3.0.en.html)

**3X-UI** — advanced, open-source web-based control panel designed for managing Xray-core server. It offers a user-friendly interface for configuring and monitoring various VPN and proxy protocols.

> [!IMPORTANT]
> This project is only for personal using, please do not use it for illegal purposes, please do not use it in a production environment.

As an enhanced fork of the original X-UI project, 3X-UI provides improved stability, broader protocol support, and additional features.

## Quick Start

```bash
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
```

For full documentation, please visit the [project Wiki](https://github.com/MHSanaei/3x-ui/wiki).

## A Special Thanks to

- [alireza0](https://github.com/alireza0/)

## Acknowledgment

- [Iran v2ray rules](https://github.com/chocolate4u/Iran-v2ray-rules) (License: **GPL-3.0**): _Enhanced v2ray/xray and v2ray/xray-clients routing rules with built-in Iranian domains and a focus on security and adblocking._
- [Russia v2ray rules](https://github.com/runetfreedom/russia-v2ray-rules-dat) (License: **GPL-3.0**): _This repository contains automatically updated V2Ray routing rules based on data on blocked domains and addresses in Russia._

## Support project

**If this project is helpful to you, you may wish to give it a**:star2:

<p align="left">
  <a href="https://buymeacoffee.com/mhsanaei" target="_blank">
    <img src="./media/buymeacoffe.png" alt="Image">
  </a>
</p>

- USDT (TRC20): `TXncxkvhkDWGts487Pjqq1qT9JmwRUz8CC`
- MATIC (polygon): `0x41C9548675D044c6Bfb425786C765bc37427256A`
- LTC (Litecoin): `ltc1q2ach7x6d2zq0n4l0t4zl7d7xe2s6fs7a3vspwv`

## Stargazers over Time

[![Stargazers over time](https://starchart.cc/MHSanaei/3x-ui.svg?variant=adaptive)](https://starchart.cc/MHSanaei/3x-ui)

# 3x-ui MySQL Edition

Версия 3x-ui панели, адаптированная для работы с MySQL вместо SQLite.

## 🚀 Особенности

- ✅ Полная поддержка MySQL 8.0+
- ✅ Автоматическое создание базы данных и таблиц
- ✅ Оптимизированная производительность для больших нагрузок
- ✅ Поддержка транзакций и ACID свойств
- ✅ Лучшая масштабируемость
- ✅ Поддержка Docker и Docker Compose
- ✅ Автоматические миграции

## 📋 Системные требования

- Ubuntu 20.04+ / Debian 11+
- MySQL 8.0+
- Go 1.24.4+
- Минимум 1GB RAM
- 10GB свободного места

## 🛠️ Установка

### Вариант 1: Автоматическая установка (Рекомендуется)

```bash
# Клонируем репозиторий
git clone https://github.com/your-username/3x-ui-mysql.git
cd 3x-ui-mysql

# Делаем скрипт исполняемым
chmod +x install_ubuntu.sh

# Запускаем установку
sudo ./install_ubuntu.sh
```

### Вариант 2: Ручная установка

#### 1. Установка MySQL

```bash
chmod +x install_mysql.sh
sudo ./install_mysql.sh
```

#### 2. Сборка и установка

```bash
chmod +x build_linux.sh
sudo ./build_linux.sh
```

#### 3. Запуск сервиса

```bash
sudo systemctl start x-ui
sudo systemctl enable x-ui
```

### Вариант 3: Docker (Для разработки)

```bash
# Запуск с Docker Compose
docker-compose -f docker-compose.mysql.yml up -d

# Или сборка и запуск вручную
docker build -f Dockerfile.mysql -t 3x-ui-mysql .
docker run -d --name 3x-ui-app -p 54321:54321 3x-ui-mysql
```

## ⚙️ Конфигурация

### Переменные окружения

```bash
export XUI_MYSQL_HOST=localhost
export XUI_MYSQL_PORT=3306
export XUI_MYSQL_USER=root
export XUI_MYSQL_PASSWORD=frif2003
export XUI_MYSQL_DATABASE=3x-ui
export XUI_DEBUG=true
export XUI_LOG_LEVEL=info
```

### Конфигурация по умолчанию

- **Хост**: localhost
- **Порт**: 3306
- **Пользователь**: root
- **Пароль**: frif2003
- **База данных**: 3x-ui

## 🗄️ Структура базы данных

### Таблицы

1. **users** - Пользователи панели
2. **inbounds** - Входящие соединения
3. **outbound_traffics** - Статистика исходящего трафика
4. **settings** - Настройки системы
5. **inbound_client_ips** - IP адреса клиентов
6. **client_traffic** - Статистика трафика клиентов
7. **history_of_seeders** - История миграций

### Автоматическая миграция

При первом запуске система автоматически:
- Создает все необходимые таблицы
- Добавляет пользователя по умолчанию (admin/admin)
- Применяет все миграции

## 🎛️ Управление сервисом

### Статус
```bash
sudo systemctl status x-ui
```

### Логи
```bash
sudo journalctl -u x-ui -f
```

### Перезапуск
```bash
sudo systemctl restart x-ui
```

### Остановка
```bash
sudo systemctl stop x-ui
```

## 🌐 Доступ к панели

После установки панель будет доступна по адресу:
- **URL**: http://your-server-ip:54321
- **Логин**: admin
- **Пароль**: admin

## 💾 Резервное копирование

### База данных
```bash
mysqldump -u root -p 3x-ui > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Восстановление
```bash
mysql -u root -p 3x-ui < backup_file.sql
```

## 🔧 Устранение неполадок

### Проверка подключения к MySQL
```bash
mysql -u root -p -h localhost
```

### Проверка статуса MySQL
```bash
sudo systemctl status mysql
```

### Просмотр логов MySQL
```bash
sudo tail -f /var/log/mysql/error.log
```

### Проверка портов
```bash
sudo netstat -tlnp | grep :3306
```

## 🔄 Обновление

1. Остановите сервис:
```bash
sudo systemctl stop x-ui
```

2. Создайте резервную копию:
```bash
mysqldump -u root -p 3x-ui > backup_before_update.sql
```

3. Обновите код и пересоберите:
```bash
git pull
sudo ./build_linux.sh
```

4. Запустите сервис:
```bash
sudo systemctl start x-ui
```

## 🔒 Безопасность

### Рекомендации

1. Измените пароль по умолчанию после первого входа
2. Используйте сильные пароли для MySQL
3. Настройте firewall для ограничения доступа
4. Регулярно обновляйте систему
5. Мониторьте логи на предмет подозрительной активности

### Настройка firewall
```bash
sudo ufw allow 54321/tcp
sudo ufw allow 443/tcp
sudo ufw allow 80/tcp
```

## 📊 Мониторинг

### Проверка производительности MySQL
```bash
mysql -u root -p -e "SHOW STATUS LIKE 'Connections';"
mysql -u root -p -e "SHOW STATUS LIKE 'Threads_connected';"
mysql -u root -p -e "SHOW PROCESSLIST;"
```

### Проверка размера базы данных
```bash
mysql -u root -p -e "SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema = '3x-ui' GROUP BY table_schema;"
```

## 🤝 Поддержка

При возникновении проблем:

1. Проверьте логи: `sudo journalctl -u x-ui -f`
2. Проверьте статус MySQL: `sudo systemctl status mysql`
3. Проверьте подключение к БД: `mysql -u root -p -h localhost`
4. Создайте issue в репозитории с подробным описанием проблемы

## 📄 Лицензия

MIT License - см. файл LICENSE для подробностей.

## 🔄 Миграция с SQLite

Если у вас есть существующая установка с SQLite, вы можете мигрировать данные:

1. Экспортируйте данные из SQLite:
```bash
sqlite3 /etc/x-ui/x-ui.db ".dump" > sqlite_backup.sql
```

2. Импортируйте в MySQL (требует ручной конвертации):
```bash
mysql -u root -p 3x-ui < converted_backup.sql
```

## 🆕 Что нового в MySQL версии

- ✅ Замена SQLite на MySQL
- ✅ Улучшенная производительность
- ✅ Поддержка транзакций
- ✅ Лучшая масштабируемость
- ✅ Автоматические резервные копии
- ✅ Docker поддержка
- ✅ Оптимизированные запросы
- ✅ Поддержка репликации
