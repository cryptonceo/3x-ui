# 3x-ui MySQL Edition

Версия 3x-ui панели, адаптированная для работы с MySQL вместо SQLite.

## Особенности

- Полная поддержка MySQL 8.0+
- Автоматическое создание базы данных и таблиц
- Оптимизированная производительность для больших нагрузок
- Поддержка транзакций и ACID свойств
- Лучшая масштабируемость

## Системные требования

- Ubuntu 20.04+ / Debian 11+
- MySQL 8.0+
- Go 1.24.4+
- Минимум 1GB RAM
- 10GB свободного места

## Установка

### 1. Клонирование репозитория

```bash
git clone https://github.com/your-username/3x-ui-mysql.git
cd 3x-ui-mysql
```

### 2. Установка MySQL

```bash
chmod +x install_mysql.sh
sudo ./install_mysql.sh
```

### 3. Сборка и установка

```bash
chmod +x build_linux.sh
sudo ./build_linux.sh
```

### 4. Запуск сервиса

```bash
sudo systemctl start x-ui
sudo systemctl enable x-ui
```

## Конфигурация

### Переменные окружения

Вы можете настроить подключение к MySQL через переменные окружения:

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

## Структура базы данных

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

## Управление сервисом

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

## Доступ к панели

После установки панель будет доступна по адресу:
- **URL**: http://your-server-ip:54321
- **Логин**: admin
- **Пароль**: admin

## Резервное копирование

### База данных
```bash
mysqldump -u root -p 3x-ui > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Восстановление
```bash
mysql -u root -p 3x-ui < backup_file.sql
```

## Устранение неполадок

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

## Обновление

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

## Безопасность

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

## Поддержка

При возникновении проблем:

1. Проверьте логи: `sudo journalctl -u x-ui -f`
2. Проверьте статус MySQL: `sudo systemctl status mysql`
3. Проверьте подключение к БД: `mysql -u root -p -h localhost`
4. Создайте issue в репозитории с подробным описанием проблемы

## Лицензия

MIT License - см. файл LICENSE для подробностей. 