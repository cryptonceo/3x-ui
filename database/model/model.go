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
    Username string `json:"username" gorm:"type:VARCHAR(255);not null;unique"`
    Password string `json:"password" gorm:"type:VARCHAR(255);not null"`
}

type Inbound struct {
    Id          int                  `json:"id" form:"id" gorm:"primaryKey;autoIncrement"`
    UserId      int                  `json:"-"`
    Up          int64                `json:"up" form:"up"`
    Down        int64                `json:"down" form:"down"`
    Total       int64                `json:"total" form:"total"`
    Remark      string               `json:"remark" form:"remark" gorm:"type:VARCHAR(255)"`
    Enable      bool                 `json:"enable" form:"enable"`
    ExpiryTime  int64                `json:"expiryTime" form:"expiryTime"`
    ClientStats []xray.ClientTraffic `gorm:"foreignKey:InboundId;references:Id" json:"clientStats" form:"clientStats"`
    Listen      string               `json:"listen" form:"listen" gorm:"type:VARCHAR(255)"`
    Port        int                  `json:"port" form:"port"`
    Protocol    Protocol             `json:"protocol" form:"protocol" gorm:"type:VARCHAR(50)"`
    Settings    string               `json:"settings" form:"settings" gorm:"type:TEXT"`
    StreamSettings string            `json:"streamSettings" form:"streamSettings" gorm:"type:TEXT"`
    Tag         string               `json:"tag" form:"tag" gorm:"unique;type:VARCHAR(255)"`
    Sniffing    string               `json:"sniffing" form:"sniffing" gorm:"type:TEXT"`
    Allocate    string               `json:"allocate" form:"allocate" gorm:"type:TEXT"`
}

type OutboundTraffics struct {
    Id    int    `json:"id" form:"id" gorm:"primaryKey;autoIncrement"`
    Tag   string `json:"tag" form:"tag" gorm:"unique;type:VARCHAR(255)"`
    Up    int64  `json:"up" form:"up" gorm:"default:0"`
    Down  int64  `json:"down" form:"down" gorm:"default:0"`
    Total int64  `json:"total" form:"total" gorm:"default:0"`
}

type InboundClientIps struct {
    Id          int    `json:"id" gorm:"primaryKey;autoIncrement"`
    ClientEmail string `json:"clientEmail" form:"clientEmail" gorm:"unique;type:VARCHAR(255)"`
    Ips         string `json:"ips" form:"ips" gorm:"type:TEXT"`
}

type HistoryOfSeeders struct {
    Id         int    `json:"id" gorm:"primaryKey;autoIncrement"`
    SeederName string `json:"seederName" gorm:"type:VARCHAR(255)"`
}

type Setting struct {
    Id        int    `json:"id" form:"id" gorm:"primaryKey;autoIncrement"`
    SettingKey string `json:"setting_key" form:"setting_key" gorm:"column:setting_key;type:VARCHAR(255);not null"`
    Value     string `json:"value" form:"value" gorm:"type:VARCHAR(255)"`
}

func (i *Inbound) GenXrayInboundConfig() *xray.InboundConfig {
    listen := i.Listen
    if listen != "" {
        listen = fmt.Sprintf("\"%v\"", listen)
    }
    return &xray.InboundConfig{
        Listen:         json_util.RawMessage(listen),
        Port:           i.Port,
        Protocol:       string(i.Protocol),
        Settings:       json_util.RawMessage(i.Settings),
        StreamSettings: json_util.RawMessage(i.StreamSettings),
        Tag:            i.Tag,
        Sniffing:       json_util.RawMessage(i.Sniffing),
        Allocate:       json_util.RawMessage(i.Allocate),
    }
}

type Client struct {
    ID         string `json:"id"`
    Security   string `json:"security" gorm:"type:VARCHAR(255)"`
    Password   string `json:"password" gorm:"type:VARCHAR(255)"`
    Flow       string `json:"flow" gorm:"type:VARCHAR(255)"`
    Email      string `json:"email" gorm:"type:VARCHAR(255)"`
    LimitIP    int    `json:"limitIp"`
    TotalGB    int64  `json:"totalGB" form:"totalGB"`
    ExpiryTime int64  `json:"expiryTime" form:"expiryTime"`
    Enable     bool   `json:"enable" form:"enable"`
    TgID       int64  `json:"tgId" form:"tgId"`
    SubID      string `json:"subId" form:"subId" gorm:"type:VARCHAR(255)"`
    Comment    string `json:"comment" form:"comment" gorm:"type:VARCHAR(255)"`
    Reset      int    `json:"reset" form:"reset"`
}