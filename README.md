# luci-app-fzu-network

福州大学校园网自动认证登录插件

> [!NOTE]
> 插件只在ImmortalWrt 25.12.0-rc2上测试过

## 功能

- 定时检测认证状态，断线后自动重新登录
- 拨号重连时通过hotplug触发登录
- 界面实时显示认证状态、账号、IP地址、MAC地址
- 运行日志实时查看

## 安装

1. 使用scp上传apk/ipk文件到路由器，例如：

```shell
scp luci-app-fzu-network-1.2.0-r1.apk root@192.168.1.1:/tmp/
# 或者
scp luci-app-fzu-network-1.2.0-r1.ipk root@192.168.1.1:/tmp/
```

1. SSH登录路由器，安装apk/ipk：

```bash
apk install --allow-untrusted /tmp/luci-app-fzu-network-1.2.0-r1.apk
# 或者
opkg install --force-checksum /tmp/luci-app-fzu-network-1.2.0-r1.ipk
```

## 配置

在界面「服务 → 福大校园网」中配置

## 组成

- LuCI界界面
- 后台脚本，负责检测认证状态和执行登录
- hotplug脚本，在网络接口状态变化时触发登录
- 定时任务，每5分钟执行一次登录检查
- 修改TTL为128的防火墙规则，用于绕过代理检测
