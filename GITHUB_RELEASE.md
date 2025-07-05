# Создание GitHub релиза для x-ui с MySQL

## Подготовка к релизу

### 1. Сборка бинарного файла

```bash
# Убедитесь, что у вас установлен Go 1.21 или новее
go version

# Запустите скрипт сборки
chmod +x build_release.sh
./build_release.sh
```

Скрипт создаст файл `x-ui-linux-amd64.tar.gz` с готовым к установке x-ui.

### 2. Содержимое архива

Архив `x-ui-linux-amd64.tar.gz` содержит:
- `x-ui` - бинарный файл для Linux amd64
- `install.sh` - автоматический скрипт установки
- `install_mysql.sh` - скрипт установки MySQL
- `install_xui_mysql.sh` - полный скрипт установки x-ui + MySQL
- `x-ui.service` - systemd сервис файл
- `README.md` - инструкции по установке
- Все необходимые директории (web/, config/, database/, etc.)

## Создание GitHub релиза

### 1. Подготовка тегов

```bash
# Создайте тег для релиза
git tag -a v1.0.0-mysql -m "x-ui with MySQL support"

# Отправьте тег в репозиторий
git push origin v1.0.0-mysql
```

### 2. Создание релиза на GitHub

1. Перейдите в ваш GitHub репозиторий
2. Нажмите "Releases" в правой панели
3. Нажмите "Create a new release"
4. Выберите тег `v1.0.0-mysql`
5. Заполните информацию о релизе:

**Заголовок:**
```
x-ui v1.0.0 with MySQL Support
```

**Описание:**
```markdown
# x-ui v1.0.0 with MySQL Support

## 🚀 Новые возможности

- ✅ Полная поддержка MySQL/MariaDB
- ✅ Автоматическая установка MySQL
- ✅ Оптимизированные SQL запросы для MySQL
- ✅ Улучшенная производительность
- ✅ Автоматическая настройка системы

## 📦 Установка

### Быстрая установка (рекомендуется)

```bash
# Скачайте релиз
wget https://github.com/cryptonceo/x-ui/releases/download/v1.0.0-mysql/x-ui-linux-amd64.tar.gz

# Распакуйте архив
tar -xzf x-ui-linux-amd64.tar.gz
cd x-ui

# Запустите установку (требуются права root)
sudo ./install.sh
```

### Ручная установка

1. Установите MySQL/MariaDB
2. Создайте базу данных и пользователя
3. Настройте переменные окружения
4. Запустите x-ui

Подробные инструкции в файле `README.md`

## 🔧 Системные требования

- Linux (Ubuntu 18.04+, Debian 9+, CentOS 7+)
- MySQL 5.7+ или MariaDB 10.3+
- 512MB RAM (минимум)
- 1GB свободного места

## 📋 Изменения

### Добавлено
- Поддержка MySQL/MariaDB
- Автоматические скрипты установки
- Оптимизированные SQL запросы
- Улучшенная обработка ошибок

### Исправлено
- Совместимость с MySQL reserved keywords
- JSON функции для MySQL
- Системные зависимости

## 🔗 Ссылки

- [Документация](README.md)
- [Issues](https://github.com/cryptonceo/x-ui/issues)
- [Discussions](https://github.com/cryptonceo/x-ui/discussions)

## 📄 Лицензия

MIT License
```

### 3. Загрузка файлов

1. В разделе "Assets" нажмите "Attach binaries"
2. Загрузите файл `x-ui-linux-amd64.tar.gz`
3. Добавьте описание файла: "x-ui Linux amd64 binary with MySQL support"

### 4. Публикация

Нажмите "Publish release"

## Инструкции для пользователей

### Установка из релиза

```bash
# 1. Скачайте релиз
wget https://github.com/cryptonceo/x-ui/releases/download/v1.0.0-mysql/x-ui-linux-amd64.tar.gz

# 2. Распакуйте архив
tar -xzf x-ui-linux-amd64.tar.gz
cd x-ui

# 3. Запустите установку
sudo ./install.sh
```

### Проверка установки

```bash
# Проверьте статус сервиса
systemctl status x-ui

# Посмотрите логи
journalctl -u x-ui -f

# Проверьте доступность панели
curl -I http://localhost:54321
```

### Доступ к панели

- URL: `http://your-server-ip:54321`
- Логин: `admin`
- Пароль: `admin`

### MySQL информация

- База данных: `xui_db`
- Пользователь: `xui_user`
- Пароль: `xui_password`

## Автоматизация релизов

Для автоматизации создания релизов можно использовать GitHub Actions:

```yaml
name: Build and Release

on:
  push:
    tags:
      - 'v*-mysql'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
          
      - name: Build x-ui
        run: |
          chmod +x build_release.sh
          ./build_release.sh
          
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: x-ui-linux-amd64.tar.gz
          body_path: GITHUB_RELEASE.md
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Поддержка

- Создавайте issues для багов
- Используйте discussions для вопросов
- Проверяйте документацию в README.md 