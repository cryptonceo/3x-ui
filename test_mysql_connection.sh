#!/bin/bash

# Скрипт для тестирования подключения к MySQL
# Автор: AI Assistant
# Версия: 1.0

set -e

echo "=== Тестирование подключения к MySQL ==="

# Проверяем переменные окружения или используем значения по умолчанию
MYSQL_HOST=${XUI_MYSQL_HOST:-localhost}
MYSQL_PORT=${XUI_MYSQL_PORT:-3306}
MYSQL_USER=${XUI_MYSQL_USER:-root}
MYSQL_PASSWORD=${XUI_MYSQL_PASSWORD:-frif2003}
MYSQL_DATABASE=${XUI_MYSQL_DATABASE:-3x-ui}

echo "Параметры подключения:"
echo "  Хост: $MYSQL_HOST"
echo "  Порт: $MYSQL_PORT"
echo "  Пользователь: $MYSQL_USER"
echo "  База данных: $MYSQL_DATABASE"
echo ""

# Проверяем, установлен ли MySQL клиент
if ! command -v mysql &> /dev/null; then
    echo "Ошибка: MySQL клиент не установлен"
    echo "Установите его командой: sudo apt-get install mysql-client"
    exit 1
fi

# Проверяем статус MySQL сервиса
echo "Проверка статуса MySQL сервиса..."
if systemctl is-active --quiet mysql; then
    echo "✅ MySQL сервис запущен"
else
    echo "❌ MySQL сервис не запущен"
    echo "Запустите его командой: sudo systemctl start mysql"
    exit 1
fi

# Тестируем подключение
echo "Тестирование подключения к MySQL..."
if mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1;" &> /dev/null; then
    echo "✅ Подключение к MySQL успешно"
else
    echo "❌ Не удалось подключиться к MySQL"
    echo "Проверьте параметры подключения и убедитесь, что MySQL запущен"
    exit 1
fi

# Проверяем существование базы данных
echo "Проверка существования базы данных '$MYSQL_DATABASE'..."
if mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "USE \`$MYSQL_DATABASE\`;" &> /dev/null; then
    echo "✅ База данных '$MYSQL_DATABASE' существует"
else
    echo "❌ База данных '$MYSQL_DATABASE' не существует"
    echo "Создайте её командой:"
    echo "mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e \"CREATE DATABASE \`$MYSQL_DATABASE\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\""
    exit 1
fi

# Проверяем таблицы
echo "Проверка таблиц в базе данных..."
TABLES=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW TABLES FROM \`$MYSQL_DATABASE\`;" 2>/dev/null | tail -n +2)

if [ -n "$TABLES" ]; then
    echo "✅ Найдены таблицы в базе данных:"
    echo "$TABLES" | while read table; do
        echo "  - $table"
    done
else
    echo "ℹ️  Таблицы в базе данных отсутствуют (будут созданы при первом запуске)"
fi

# Проверяем права пользователя
echo "Проверка прав пользователя..."
RIGHTS=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW GRANTS FOR '$MYSQL_USER'@'$MYSQL_HOST';" 2>/dev/null)

if echo "$RIGHTS" | grep -q "ALL PRIVILEGES ON \`$MYSQL_DATABASE\`"; then
    echo "✅ Пользователь имеет все необходимые права"
else
    echo "❌ Пользователь не имеет необходимых прав"
    echo "Выполните команду:"
    echo "mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e \"GRANT ALL PRIVILEGES ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'$MYSQL_HOST'; FLUSH PRIVILEGES;\""
fi

# Проверяем версию MySQL
echo "Проверка версии MySQL..."
VERSION=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT VERSION();" 2>/dev/null | tail -n +2)
echo "✅ Версия MySQL: $VERSION"

# Проверяем кодировку
echo "Проверка кодировки базы данных..."
CHARSET=$(mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$MYSQL_DATABASE';" 2>/dev/null | tail -n +2)
echo "✅ Кодировка базы данных: $CHARSET"

echo ""
echo "=== Тестирование завершено успешно ==="
echo "MySQL готов к работе с 3x-ui!" 