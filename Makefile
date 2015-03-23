include $(TOPDIR)/rules.mk

PKG_NAME:=doghole
PKG_VERSION:=0.1
PKG_RELEASE:=1
PKG_MAINTAINER:=Jason Tse <jasontsecode@gmail.com>
PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/doghole
   SECTION:=net
   CATEGORY:=Network
   SUBMENU:=Routing and Redirection
   DEPENDS:=+dnsmasq-full +ip +ipset +iptables +iptables-mod-ipopt +shadowvpn +luci-proto-shadowvpn +luci-app-commands +ChinaDNS +luci-app-chinadns
   TITLE:=Science networking solution based on ShadowVPN
   MAINTAINER:=Jason Tse <jasontsecode@gmail.com>
   PKGARCH:=all
endef

define Package/doghole/description
Science networking solution based on ShadowVPN
endef

define Package/doghole/conffiles
/etc/config/doghole
/etc/doghole/dnsmasq.d/custom.conf
endef

define Package/doghole/install
	$(INSTALL_DIR) $(1)/etc/doghole/dnsmasq.d
	$(INSTALL_DIR) $(1)/etc/shadowvpn/up.d
	$(INSTALL_DIR) $(1)/etc/shadowvpn/down.d
	$(INSTALL_DIR) $(1)/bin
	$(INSTALL_CONF) ./files/doghole.rtbl $(1)/etc/doghole/
	$(INSTALL_CONF) ./files/CN.rtbl $(1)/etc/doghole/
	$(INSTALL_CONF) ./files/firewall $(1)/etc/doghole/
	$(INSTALL_CONF) ./files/ipset.conf $(1)/etc/doghole/dnsmasq.d/
	$(INSTALL_CONF) ./files/custom.conf $(1)/etc/doghole/dnsmasq.d/
	$(INSTALL_BIN) ./files/doghole-up $(1)/etc/shadowvpn/up.d/
	$(INSTALL_BIN) ./files/doghole-down $(1)/etc/shadowvpn/down.d/
	$(INSTALL_BIN) ./files/doghole $(1)/bin/
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/doghole.config $(1)/etc/config/doghole
	$(INSTALL_DIR) $(1)/etc/uci-defaults/
	$(INSTALL_BIN) ./files/doghole.uci-defaults $(1)/etc/uci-defaults/luci-doghole
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/doghole.controller $(1)/usr/lib/lua/luci/controller/doghole.lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) ./files/doghole.zh-cn.lmo $(1)/usr/lib/lua/luci/i18n/doghole.zh-cn.lmo
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/doghole
	$(INSTALL_DATA) ./files/globals.cbi $(1)/usr/lib/lua/luci/model/cbi/doghole/globals.lua
	$(INSTALL_DATA) ./files/policies.cbi $(1)/usr/lib/lua/luci/model/cbi/doghole/policies.lua
	$(INSTALL_DATA) ./files/dnsmasq.cbi $(1)/usr/lib/lua/luci/model/cbi/doghole/dnsmasq.lua
endef

define Package/doghole/preinst
#!/bin/sh
[ -z "$$IPKG_INSTROOT" ] && ifdown doghole >/dev/null
exit 0
endef

define Package/doghole/postinst
#!/bin/sh
[ ! -z "$${IPKG_INSTROOT}" ] && exit 0
INCLUDED=1
. /etc/uci-defaults/luci-doghole
rm -f /etc/uci-defaults/luci-doghole
/etc/init.d/chinadns restart
/etc/init.d/dnsmasq restart
/etc/init.d/network reload
/etc/init.d/firewall restart
ifup doghole >/dev/null
endef

define Package/doghole/postrm
#!/bin/sh
[ ! -z "$${IPKG_INSTROOT}" ] && exit 0
sed -i '/^200\tdoghole/d' /etc/iproute2/rt_tables
sed -i '/^conf-dir=\/etc\/doghole\/dnsmasq.d/d' /etc/dnsmasq.conf
/etc/init.d/dnsmasq restart
uci -q batch <<-EOF >/dev/null
    delete firewall.doghole
    commit firewall
    delete luci.doghole
    commit luci
EOF
/etc/init.d/firewall restart
ipset destroy rtbl
ipset destroy doghole
ipset destroy CN
rm -rf /tmp/luci-modulecache /tmp/luci-indexcache
endef

define Build/Compile
endef

$(eval $(call BuildPackage,doghole))
