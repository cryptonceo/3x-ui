package config

import (
	_ "embed"
	"fmt"
	"os"
	"strings"
)

//go:embed version
var version string

//go:embed name
var name string

type LogLevel string

const (
	Debug  LogLevel = "debug"
	Info   LogLevel = "info"
	Notice LogLevel = "notice"
	Warn   LogLevel = "warn"
	Error  LogLevel = "error"
)

func GetVersion() string {
	return strings.TrimSpace(version)
}

func GetName() string {
	return strings.TrimSpace(name)
}

func GetLogLevel() LogLevel {
	if IsDebug() {
		return Debug
	}
	logLevel := os.Getenv("XUI_LOG_LEVEL")
	if logLevel == "" {
		return Info
	}
	return LogLevel(logLevel)
}

func IsDebug() bool {
	return os.Getenv("XUI_DEBUG") == "true"
}

func GetBinFolderPath() string {
	binFolderPath := os.Getenv("XUI_BIN_FOLDER")
	if binFolderPath == "" {
		binFolderPath = "bin"
	}
	return binFolderPath
}

// MySQL конфигурация
func GetMySQLHost() string {
	host := os.Getenv("XUI_MYSQL_HOST")
	if host == "" {
		host = "localhost"
	}
	return host
}

func GetMySQLPort() int {
	port := os.Getenv("XUI_MYSQL_PORT")
	if port == "" {
		return 3306
	}
	// Здесь можно добавить парсинг порта если нужно
	return 3306
}

func GetMySQLUser() string {
	user := os.Getenv("XUI_MYSQL_USER")
	if user == "" {
		user = "root"
	}
	return user
}

func GetMySQLPassword() string {
	password := os.Getenv("XUI_MYSQL_PASSWORD")
	if password == "" {
		password = "frif2003"
	}
	return password
}

func GetMySQLDatabase() string {
	database := os.Getenv("XUI_MYSQL_DATABASE")
	if database == "" {
		database = "3x-ui"
	}
	return database
}

func GetMySQLDSN() string {
	return fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		GetMySQLUser(), GetMySQLPassword(), GetMySQLHost(), GetMySQLPort(), GetMySQLDatabase())
}

// Оставляем для совместимости, но теперь возвращаем путь к логам
func GetDBFolderPath() string {
	dbFolderPath := os.Getenv("XUI_DB_FOLDER")
	if dbFolderPath == "" {
		dbFolderPath = "/etc/x-ui"
	}
	return dbFolderPath
}

// Оставляем для совместимости, но теперь возвращаем путь к логам
func GetDBPath() string {
	return fmt.Sprintf("%s/%s.log", GetDBFolderPath(), GetName())
}

func GetLogFolder() string {
	logFolderPath := os.Getenv("XUI_LOG_FOLDER")
	if logFolderPath == "" {
		logFolderPath = "/var/log"
	}
	return logFolderPath
}
