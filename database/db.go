package database

import (
	"log"
	"x-ui/config"
	"x-ui/database/model"
	"x-ui/util/crypto"
	"x-ui/xray"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var db *gorm.DB

const (
	defaultUsername = "admin"
	defaultPassword = "admin"
)

func InitDB(dsn string) error {
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
	db, err = gorm.Open(mysql.Open(dsn), c)
	if err != nil {
		return err
	}

	if err := initModels(); err != nil {
		return err
	}

	isUsersEmpty, err := isTableEmpty("users")
	if err != nil {
		return err
	}

	if err := initUser(); err != nil {
		return err
	}

	return runSeeders(isUsersEmpty)
}

func initModels() error {
	return db.AutoMigrate(
		&model.User{},
		&model.Inbound{},
		&model.Setting{},
		&model.ClientTraffic{},
		&model.InboundClientIps{},
	)
}

func isTableEmpty(tableName string) (bool, error) {
	var count int64
	err := db.Table(tableName).Count(&count).Error
	if err != nil {
		return false, err
	}
	return count == 0, nil
}

func initUser() error {
	var count int64
	err := db.Model(&model.User{}).Count(&count).Error
	if err != nil {
		return err
	}

	if count == 0 {
		user := model.User{
			Username: defaultUsername,
			Password: crypto.SHA256(defaultPassword),
		}
		return db.Create(&user).Error
	}
	return nil
}

func runSeeders(isUsersEmpty bool) error {
	if isUsersEmpty {
		log.Println("Running seeders for initial data...")
	}
	return nil
}

func GetDB() *gorm.DB {
	return db
}
