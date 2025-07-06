-- Инициализация базы данных 3x-ui для MySQL
-- Автор: AI Assistant
-- Версия: 1.0

-- Создаем базу данных если она не существует
CREATE DATABASE IF NOT EXISTS `3x-ui` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Используем базу данных
USE `3x-ui`;

-- Создаем пользователя и даем права
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'frif2003';
GRANT ALL PRIVILEGES ON `3x-ui`.* TO 'root'@'%';
FLUSH PRIVILEGES;

-- Создаем таблицы (GORM автоматически создаст их при первом запуске)
-- Но мы можем создать базовые таблицы заранее

-- Таблица пользователей
CREATE TABLE IF NOT EXISTS `users` (
    `id` int NOT NULL AUTO_INCREMENT,
    `username` varchar(255) NOT NULL,
    `password` varchar(255) NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица входящих соединений
CREATE TABLE IF NOT EXISTS `inbounds` (
    `id` int NOT NULL AUTO_INCREMENT,
    `user_id` int NOT NULL,
    `up` bigint NOT NULL DEFAULT 0,
    `down` bigint NOT NULL DEFAULT 0,
    `total` bigint NOT NULL DEFAULT 0,
    `remark` varchar(255) DEFAULT NULL,
    `enable` tinyint(1) NOT NULL DEFAULT 1,
    `expiry_time` bigint NOT NULL DEFAULT 0,
    `listen` varchar(255) DEFAULT NULL,
    `port` int NOT NULL,
    `protocol` varchar(50) NOT NULL,
    `settings` text,
    `stream_settings` text,
    `tag` varchar(255) UNIQUE,
    `sniffing` text,
    `allocate` text,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица исходящего трафика
CREATE TABLE IF NOT EXISTS `outbound_traffics` (
    `id` int NOT NULL AUTO_INCREMENT,
    `tag` varchar(255) UNIQUE,
    `up` bigint NOT NULL DEFAULT 0,
    `down` bigint NOT NULL DEFAULT 0,
    `total` bigint NOT NULL DEFAULT 0,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица настроек
CREATE TABLE IF NOT EXISTS `settings` (
    `id` int NOT NULL AUTO_INCREMENT,
    `key` varchar(255) NOT NULL,
    `value` text,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица IP адресов клиентов
CREATE TABLE IF NOT EXISTS `inbound_client_ips` (
    `id` int NOT NULL AUTO_INCREMENT,
    `client_email` varchar(255) UNIQUE,
    `ips` text,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица трафика клиентов
CREATE TABLE IF NOT EXISTS `client_traffic` (
    `id` int NOT NULL AUTO_INCREMENT,
    `inbound_id` int NOT NULL,
    `email` varchar(255) NOT NULL,
    `up` bigint NOT NULL DEFAULT 0,
    `down` bigint NOT NULL DEFAULT 0,
    `total` bigint NOT NULL DEFAULT 0,
    `expiry_time` bigint NOT NULL DEFAULT 0,
    `enable` tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`inbound_id`) REFERENCES `inbounds`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица истории миграций
CREATE TABLE IF NOT EXISTS `history_of_seeders` (
    `id` int NOT NULL AUTO_INCREMENT,
    `seeder_name` varchar(255) NOT NULL,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Создаем индексы для оптимизации
CREATE INDEX idx_inbounds_user_id ON `inbounds`(`user_id`);
CREATE INDEX idx_inbounds_protocol ON `inbounds`(`protocol`);
CREATE INDEX idx_inbounds_enable ON `inbounds`(`enable`);
CREATE INDEX idx_client_traffic_inbound_id ON `client_traffic`(`inbound_id`);
CREATE INDEX idx_client_traffic_email ON `client_traffic`(`email`);
CREATE INDEX idx_settings_key ON `settings`(`key`);

-- Показываем созданные таблицы
SHOW TABLES; 