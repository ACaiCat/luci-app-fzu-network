# luci-app-fzu-network

福州大学校园网自动认证登录插件

## 功能

- 定时检测认证状态，断线后自动重新登录
- 拨号重连时通过hotplug触发登录
- 界面实时显示认证状态、账号、IP地址、MAC地址
- 运行日志实时查看

## 文件结构

```txt
files/
├── luci/
│   ├── controller/fzu-network.lua    # 菜单注册
│   └── model/cbi/fzu-network.lua     # 配置页面
└── root/
    ├── etc/config/fzu-network        # UCI 配置
    ├── etc/init.d/fzu-network        # 服务脚本（cron + hotplug）
    ├── etc/uci-defaults/fzu-network  # 安装初始化
    └── usr/sbin/fzu-network          # 主认证脚本
```

## 配置

配置文件路径：`/etc/config/fzu-network`，也可在界面「服务 → 福大校园网」中配置。

```txt
config base 'base'
    option enable     '1'
    option school_no  '你的学号或工号'
    option password   '你的密码'
    option time       '5'              # 检测间隔，单位：分钟
    option user_agent 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) ...'
```

## 编译

```bash
# 克隆到 SDK 的 package 目录
git clone https://github.com/yourname/luci-app-fzu-network package/luci-app-fzu-network

# 选择软件包
make menuconfig
# 路径：LuCI → Applications → luci-app-fzu-network

# 编译
make package/luci-app-fzu-network/compile V=s
```

编译产物位于 `bin/packages/<arch>/base/luci-app-fzu-network_*.ipk`。

## 认证流程

本插件适配 H3C iMC 认证系统，认证服务器为 `172.16.0.46`。

1. 访问 `http://123.123.123.123`，获取认证重定向地址
2. 请求 `pageInfo` 接口，获取 JSESSIONID 与认证参数
3. 调用 `login` 接口，提交学号和密码完成认证