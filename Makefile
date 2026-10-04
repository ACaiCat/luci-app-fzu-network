include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-fzu-network
PKG_VERSION:=1.4.3
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=ACaiCat <13110818005@qq.com>

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-fzu-network
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for FZU Campus Network
	PKGARCH:=all
	DEPENDS:=+curl +jq +luci-base
endef

define Package/luci-app-fzu-network/description
	福州大学校园网自动认证登录
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-fzu-network/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	if [ -f /etc/uci-defaults/fzu-network ]; then
		( . /etc/uci-defaults/fzu-network ) && \
		rm -f /etc/uci-defaults/fzu-network
	fi
	/etc/init.d/ttl128 enable || true
	/etc/init.d/ttl128 start || true
	# 配置保存后自动 reload 依赖 ucitrack 触发器，而 ucitrack 只给已 enable 的
	# init 脚本注册触发器；start() 内部仍会检查 UCI 的 enable 开关，所以提前
	# enable 不会绕过开关启动服务。
	/etc/init.d/fzu-network enable || true
	/etc/init.d/fzu-network start || true
	/etc/init.d/ucitrack restart || true
	# rpcd 只在启动时扫描一次 /usr/libexec/rpcd/ 并把方法注册进 ubus，
	# 不 reload 的话新加的 ubus 方法要重启路由器才生效
	/etc/init.d/rpcd reload || true
	rm -rf /tmp/luci-indexcache /tmp/luci-modulecache
fi
exit 0
endef

define Package/luci-app-fzu-network/prerm
#!/bin/sh
/etc/init.d/fzu-network stop || true
/etc/init.d/fzu-network disable || true
/etc/init.d/ttl128 stop || true
/etc/init.d/ttl128 disable || true
exit 0
endef

define Package/luci-app-fzu-network/conffiles
/etc/config/fzu-network
endef

define Package/luci-app-fzu-network/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view
	$(INSTALL_DATA) ./files/root/www/luci-static/resources/view/fzu-network.js $(1)/www/luci-static/resources/view/fzu-network.js
	$(INSTALL_DIR) $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) ./files/root/usr/libexec/rpcd/luci.fzu-network $(1)/usr/libexec/rpcd/luci.fzu-network
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/root/etc/config/fzu-network $(1)/etc/config/fzu-network
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/root/etc/init.d/fzu-network $(1)/etc/init.d/fzu-network
	$(INSTALL_BIN) ./files/root/etc/init.d/ttl128 $(1)/etc/init.d/ttl128
	$(INSTALL_DIR) $(1)/etc/nftables.d
	$(INSTALL_DATA) ./files/root/etc/nftables.d/12-fzu-network-ttl-128.nft $(1)/etc/nftables.d/12-fzu-network-ttl-128.nft
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/root/etc/uci-defaults/fzu-network $(1)/etc/uci-defaults/fzu-network
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/root/usr/sbin/fzu-network $(1)/usr/sbin/fzu-network
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./files/root/usr/share/luci/menu.d/luci-app-fzu-network.json $(1)/usr/share/luci/menu.d/luci-app-fzu-network.json
	$(INSTALL_DIR) $(1)/usr/share/ucitrack
	$(INSTALL_DATA) ./files/root/usr/share/ucitrack/luci-app-fzu-network.json $(1)/usr/share/ucitrack/luci-app-fzu-network.json
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/root/usr/share/rpcd/acl.d/luci-app-fzu-network.json $(1)/usr/share/rpcd/acl.d/luci-app-fzu-network.json
endef

$(eval $(call BuildPackage,luci-app-fzu-network))