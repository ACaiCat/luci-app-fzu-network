# luci-app-fzu-network

福州大学校园网自动认证登录插件

> [!WARNING]
> 插件只在ImmortalWrt 25.12.0-rc2上测试过

## 功能

- 定时检测认证状态，断线后自动重新登录
- 拨号重连时通过hotplug触发登录
- 界面实时显示认证状态、账号、IP地址、MAC地址、下次检查倒计时
- 界面可设置检查间隔（秒），并提供「刷新登录」按钮立即检查一次
- 运行日志实时查看
- 不依赖cron，后台常驻进程按设定间隔检测，可通过命名管道即时下发命令

## 安装

1. 使用scp上传apk/ipk文件到路由器，例如：

  ```shell
  scp luci-app-fzu-network-1.4.1-r1.apk root@192.168.1.1:/tmp/
  # 或者
  scp luci-app-fzu-network_1.4.1-1_all.ipk root@192.168.1.1:/tmp/
  ```

2. SSH登录路由器，安装apk/ipk：

  ```bash
  apk add --allow-untrusted /tmp/luci-app-fzu-network-1.4.1-r1.apk
  # 或者
  opkg install --force-checksum /tmp/luci-app-fzu-network_1.4.1-1_all.ipk
  ```

## 配置

在界面「服务 → 福大校园网」中配置，点击「保存并应用」后会自动通知常驻进程重读配置，无需重启服务。

## 组成

- LuCI界界面
- 常驻进程（`/usr/sbin/fzu-network`），按间隔检测认证状态并执行登录
- hotplug脚本，在网络接口状态变化时通知进程立即检查
- 修改TTL为128的防火墙规则，用于绕过代理检测

## 命令

进程以常驻方式运行，外部通过命名管道 `/var/run/fzu-network.fifo` 向它下发命令：

```bash
/usr/sbin/fzu-network cmd check    # 立即检查一次
/usr/sbin/fzu-network cmd login    # 立即登录一次
/usr/sbin/fzu-network cmd reload   # 重新读取UCI配置
/usr/sbin/fzu-network cmd stop     # 退出进程

/etc/init.d/fzu-network start|stop|restart|status
/etc/init.d/fzu-network check          # 立即检查一次
/etc/init.d/fzu-network reload_config  # 重新读取UCI配置
```

检查间隔由UCI选项 `fzu-network.base.interval` 控制（单位秒，默认180）。
