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

func GetDBFolderPath() string {
	dbFolderPath := os.Getenv("XUI_DB_FOLDER")
	if dbFolderPath == "" {
		dbFolderPath = "/etc/x-ui"
	}
	return dbFolderPath
}

func GetDBPath() string {
	return fmt.Sprintf("%s/%s.db", GetDBFolderPath(), GetName())
}

func GetLogFolder() string {
	logFolderPath := os.Getenv("XUI_LOG_FOLDER")
	if logFolderPath == "" {
		logFolderPath = "/var/log"
	}
	return logFolderPath
}

func GetDBType() string {
	dbType := os.Getenv("XUI_DB_TYPE")
	if dbType == "" {
		// Default to MySQL for better performance
		dbType = "mysql"
	}
	return dbType
}

func GetDBDSN() string {
	dsn := os.Getenv("XUI_DB_DSN")
	if dsn == "" {
		// Default MySQL DSN
		dsn = "root:password@tcp(127.0.0.1:3306)/xui_db?charset=utf8mb4&parseTime=True&loc=Local"
	}
	return dsn
}

// GetMySQLConfig returns MySQL-specific configuration
func GetMySQLConfig() (string, string, string, string, string) {
	dsn := GetDBDSN()
	
	// Parse DSN to extract components
	// Format: username:password@tcp(host:port)/database?params
	parts := strings.Split(dsn, "@")
	if len(parts) != 2 {
		return "root", "password", "127.0.0.1", "3306", "xui_db"
	}
	
	userPass := strings.Split(parts[0], ":")
	hostDB := strings.Split(parts[1], "/")
	
	username := "root"
	password := "password"
	if len(userPass) == 2 {
		username = userPass[0]
		password = userPass[1]
	}
	
	host := "127.0.0.1"
	port := "3306"
	database := "xui_db"
	
	if len(hostDB) == 2 {
		// Extract host and port
		hostPort := strings.TrimPrefix(hostDB[0], "tcp(")
		hostPort = strings.TrimSuffix(hostPort, ")")
		hp := strings.Split(hostPort, ":")
		if len(hp) == 2 {
			host = hp[0]
			port = hp[1]
		} else {
			host = hostPort
		}
		
		// Extract database name
		dbParts := strings.Split(hostDB[1], "?")
		if len(dbParts) > 0 {
			database = dbParts[0]
		}
	}
	
	return username, password, host, port, database
}