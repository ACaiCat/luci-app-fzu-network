include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-fzu-network
PKG_VERSION:=1.1.0
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=ACaiCat

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-fzu-network
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=LuCI Support for FZU Campus Network
	PKGARCH:=all
	DEPENDS:=+curl +jq +luci-compat
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
	/etc/init.d/ttl128 enable
	/etc/init.d/ttl128 start
	rm -rf /tmp/luci-indexcache /tmp/luci-modulecache
fi
exit 0
endef

define Package/luci-app-fzu-network/prerm
#!/bin/sh
/etc/init.d/fzu-network stop
/etc/init.d/ttl128 stop
/etc/init.d/ttl128 disable
exit 0
endef

define Package/luci-app-fzu-network/conffiles
/etc/config/fzu-network
endef

define Package/luci-app-fzu-network/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/root/usr/lib/lua/luci/controller/fzu_network.lua $(1)/usr/lib/lua/luci/controller/fzu_network.lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DATA) ./files/root/usr/lib/lua/luci/model/cbi/fzu-network.lua $(1)/usr/lib/lua/luci/model/cbi/fzu-network.lua
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/root/etc/config/fzu-network $(1)/etc/config/fzu-network
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/root/etc/init.d/fzu-network $(1)/etc/init.d/fzu-network
	$(INSTALL_BIN) ./files/root/etc/init.d/ttl128 $(1)/etc/init.d/ttl128
	$(INSTALL_DIR) $(1)/etc/nftables.d
	$(INSTALL_DATA) ./files/root/etc/nftables.d/12-mangle-ttl-128.nft $(1)/etc/nftables.d/12-mangle-ttl-128.nft
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/root/etc/uci-defaults/fzu-network $(1)/etc/uci-defaults/fzu-network
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) ./files/root/usr/sbin/fzu-network $(1)/usr/sbin/fzu-network
endef

$(eval $(call BuildPackage,luci-app-fzu-network))
