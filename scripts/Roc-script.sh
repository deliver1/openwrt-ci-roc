#!/usr/bin/env bash
set -feuo pipefail

# ==========================================
# 1. 基础网络设置 (量身定制版)
# ==========================================
# 默认 IP 设置为 192.168.10.1，刷完直接无缝接管当前网络
sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate
# 主机名锁定为 OWRT
sed -i "s/hostname='.*'/hostname='OWRT'/g" package/base-files/files/bin/config_generate

# ==========================================
# 2. 清除不需要的自带依赖 (防止冲突)
# ==========================================
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/luci/applications/luci-app-upnp
rm -rf feeds/luci/applications/luci-app-wol
rm -rf feeds/packages/net/miniupnpd
rm -rf feeds/packages/lang/golang

# ==========================================
# 3. 修复 128 报错：精准拉取依赖 (不再报错)
# ==========================================
# 拉取 Golang 依赖 (HomeProxy 需要)
git clone --depth=1 --single-branch --filter=blob:none --sparse https://github.com/laipeng668/packages temp_golang
cd temp_golang
git sparse-checkout set lang/golang
cd ..
mv -f temp_golang/lang/golang feeds/packages/lang/
rm -rf temp_golang

# 拉取 UPnP 依赖
git clone --depth=1 --single-branch --filter=blob:none --sparse https://github.com/immortalwrt/packages temp_pkg
cd temp_pkg
git sparse-checkout set net/miniupnpd
cd ..
mv -f temp_pkg/net/miniupnpd feeds/packages/net/
rm -rf temp_pkg

# 拉取 LuCI 插件 (UPnP & WOL)
git clone --depth=1 --single-branch --filter=blob:none --sparse https://github.com/immortalwrt/luci temp_luci
cd temp_luci
git sparse-checkout set applications/luci-app-upnp applications/luci-app-wol
cd ..
mv -f temp_luci/applications/luci-app-upnp feeds/luci/applications/
mv -f temp_luci/applications/luci-app-wol feeds/luci/applications/
rm -rf temp_luci

# ==========================================
# 4. 更新 Argon 主题
# ==========================================
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# ==========================================
# 5. 更新并安装包源
# ==========================================
./scripts/feeds update -a
./scripts/feeds install -a
