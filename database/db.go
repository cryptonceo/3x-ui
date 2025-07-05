package database

import (
	"bytes"
	"fmt"
	"io"
	"io/fs"
	"log"
	"os"
	"path"
	"slices"

	"x-ui/config"
	"x-ui/database/model"
	"x-ui/util/crypto"
	"x-ui/xray"

	"gorm.io/driver/mysql"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var db *gorm.DB

const (
	defaultUsername = "admin"
	defaultPassword = "admin"
)

func initModels() error {
    log.Println("Running AutoMigrate for models")
    models := []any{
        &model.User{},
        &model.Inbound{},
        &model.OutboundTraffics{},
        &model.Setting{},
        &model.InboundClientIps{},
        &xray.ClientTraffic{},
        &model.HistoryOfSeeders{},
    }
    for _, model := range models {
        log.Printf("Migrating model: %T", model)
        if err := db.AutoMigrate(model); err != nil {
            log.Printf("Error auto migrating model %T: %v", model, err)
            return err
        }
    }
    return nil
}

func initUser() error {
	empty, err := isTableEmpty("users")
	if err != nil {
		log.Printf("Error checking if users table is empty: %v", err)
		return err
	}
	if empty {
		hashedPassword, err := crypto.HashPasswordAsBcrypt(defaultPassword)
		if err != nil {
			log.Printf("Error hashing default password: %v", err)
			return err
		}

		user := &model.User{
			Username: defaultUsername,
			Password: hashedPassword,
		}
		return db.Create(user).Error
	}
	return nil
}

func runSeeders(isUsersEmpty bool) error {
	empty, err := isTableEmpty("history_of_seeders")
	if err != nil {
		log.Printf("Error checking if history_of_seeders table is empty: %v", err)
		return err
	}

	if empty && isUsersEmpty {
		hashSeeder := &model.HistoryOfSeeders{
			SeederName: "UserPasswordHash",
		}
		return db.Create(hashSeeder).Error
	} else {
		var seedersHistory []string
		db.Model(&model.HistoryOfSeeders{}).Pluck("seeder_name", &seedersHistory)

		if !slices.Contains(seedersHistory, "UserPasswordHash") && !isUsersEmpty {
			var users []model.User
			db.Find(&users)

			for _, user := range users {
				hashedPassword, err := crypto.HashPasswordAsBcrypt(user.Password)
				if err != nil {
					log.Printf("Error hashing password for user '%s': %v", user.Username, err)
					return err
				}
				db.Model(&user).Update("password", hashedPassword)
			}

			hashSeeder := &model.HistoryOfSeeders{
				SeederName: "UserPasswordHash",
			}
			return db.Create(hashSeeder).Error
		}
	}

	return nil
}

func isTableEmpty(tableName string) (bool, error) {
	var count int64
	err := db.Table(tableName).Count(&count).Error
	return count == 0, err
}

// setupMySQLDatabase ensures MySQL database and user exist
func setupMySQLDatabase() error {
	username, password, host, port, database := config.GetMySQLConfig()
	
	log.Printf("Setting up MySQL database: %s on %s:%s", database, host, port)
	
	// Create a temporary connection to MySQL server (without specifying database)
	tempDSN := fmt.Sprintf("%s:%s@tcp(%s:%s)/?charset=utf8mb4&parseTime=True&loc=Local", 
		username, password, host, port)
	
	tempDB, err := gorm.Open(mysql.Open(tempDSN), &gorm.Config{})
	if err != nil {
		return fmt.Errorf("failed to connect to MySQL server: %v", err)
	}
	
	// Create database if it doesn't exist
	sqlDB, err := tempDB.DB()
	if err != nil {
		return fmt.Errorf("failed to get underlying sql.DB: %v", err)
	}
	defer sqlDB.Close()
	
	// Create database
	err = tempDB.Exec(fmt.Sprintf("CREATE DATABASE IF NOT EXISTS `%s` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci", database)).Error
	if err != nil {
		return fmt.Errorf("failed to create database %s: %v", database, err)
	}
	
	log.Printf("MySQL database '%s' is ready", database)
	return nil
}

func InitDB() error {
    dbType := config.GetDBType()
    var dialector gorm.Dialector
    
    log.Printf("Initializing database with type: %s", dbType)
    
    if dbType == "mysql" {
        // Setup MySQL database first
        if err := setupMySQLDatabase(); err != nil {
            log.Printf("Warning: MySQL setup failed: %v", err)
            log.Printf("Continuing with existing database...")
        }
        
        dsn := config.GetDBDSN()
        log.Printf("Connecting to MySQL with DSN: %s", dsn)
        dialector = mysql.Open(dsn)
    } else {
        // Default to SQLite
        dbPath := config.GetDBPath()
        dir := path.Dir(dbPath)
        err := os.MkdirAll(dir, fs.ModePerm)
        if err != nil {
            return fmt.Errorf("failed to create database directory: %v", err)
        }
        log.Printf("Using SQLite database at: %s", dbPath)
        dialector = sqlite.Open(dbPath)
    }
    
    var gormLogger logger.Interface
    if config.IsDebug() {
        gormLogger = logger.Default
    } else {
        gormLogger = logger.Discard
    }
    
    c := &gorm.Config{
        Logger: gormLogger,
    }
    
    var err error
    db, err = gorm.Open(dialector, c)
    if err != nil {
        return fmt.Errorf("failed to connect to database: %v", err)
    }
    
    log.Printf("Database connection established successfully")
    
    if err := initModels(); err != nil {
        return fmt.Errorf("failed to initialize models: %v", err)
    }
    
    isUsersEmpty, err := isTableEmpty("users")
    if err != nil {
        return fmt.Errorf("failed to check users table: %v", err)
    }
    
    if err := initUser(); err != nil {
        return fmt.Errorf("failed to initialize user: %v", err)
    }
    
    if err := runSeeders(isUsersEmpty); err != nil {
        return fmt.Errorf("failed to run seeders: %v", err)
    }
    
    log.Printf("Database initialization completed successfully")
    return nil
}

func CloseDB() error {
	if db != nil {
		sqlDB, err := db.DB()
		if err != nil {
			return err
		}
		return sqlDB.Close()
	}
	return nil
}

func GetDB() *gorm.DB {
	return db
}

func IsNotFound(err error) bool {
	return err == gorm.ErrRecordNotFound
}

func IsSQLiteDB(file io.ReaderAt) (bool, error) {
	signature := []byte("SQLite format 3\x00")
	buf := make([]byte, len(signature))
	_, err := file.ReadAt(buf, 0)
	if err != nil {
		return false, err
	}
	return bytes.Equal(buf, signature), nil
}

func Checkpoint() error {
    return nil // MySQL doesn't require checkpoint
}