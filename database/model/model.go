package model

import (
	"fmt"

	"x-ui/util/json_util"
	"x-ui/xray"
)

type Protocol string

const (
	VMESS       Protocol = "vmess"
	VLESS       Protocol = "vless"
	DOKODEMO    Protocol = "dokodemo-door"
	HTTP        Protocol = "http"
	Trojan      Protocol = "trojan"
	Shadowsocks Protocol = "shadowsocks"
	Socks       Protocol = "socks"
	WireGuard   Protocol = "wireguard"
)

type User struct {
	Id       int    `json:"id" gorm:"primaryKey;autoIncrement"`
	Username string `json:"username"`
	Password string `json:"password"`
}

type Inbound struct {
	Id           int            `json:"id" gorm:"primaryKey;autoIncrement"`
	UserId       int            `json:"userId"`
	Up           int64          `json:"up"`
	Down         int64          `json:"down"`
	Total        int64          `json:"total"`
	Remark       string         `json:"remark"`
	Enable       bool           `json:"enable"`
	ExpiryTime   int64          `json:"expiryTime"`
	ClientStats  json_util.RawMessage `json:"clientStats" gorm:"type:json"`
	Listen       string         `json:"listen"`
	Port         int            `json:"port"`
	Protocol     Protocol       `json:"protocol"`
	Settings     string         `json:"settings"`
	StreamSettings string       `json:"streamSettings"`
	Tag          string         `json:"tag"`
	Sniffing     string         `json:"sniffing"`
}

type Setting struct {
	Id    int    `json:"id" gorm:"primaryKey;autoIncrement"`
	Key   string `json:"key"`
	Value string `json:"value"`
}

type ClientTraffic struct {
	Id     int   `json:"id" gorm:"primaryKey;autoIncrement"`
	InboundId int `json:"inboundId"`
	Email     string `json:"email"`
	Up        int64  `json:"up"`
	Down      int64  `json:"down"`
}

type InboundClientIps struct {
	Id        int    `json:"id" gorm:"primaryKey;autoIncrement"`
	InboundId int    `json:"inboundId"`
	Email     string `json:"email"`
	Ips       string `json:"ips"`
}
