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
# 2. 清除不需要的自带依赖 (防止后台幽灵编译)
# ==========================================
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/luci/applications/luci-app-upnp
rm -rf feeds/luci/applications/luci-app-wol
rm -rf feeds/packages/net/miniupnpd
rm -rf feeds/packages/lang/golang

# ==========================================
# 3. 核心 Git 拉取函数
# ==========================================
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# ==========================================
# 4. 仅拉取最基础且必需的网络库 (剔除所有第三方全家桶)
# ==========================================
# 更新 Golang 1.22+ (HomeProxy 及 sing-box 强依赖环境)
git clone https://github.com/laipeng668/packages_lang_golang feeds/packages/lang/golang

# 更新基础 UPnP 和 WOL
git_sparse_clone master https://github.com/immortalwrt/packages net/miniupnpd
git_sparse_clone master https://github.com/immortalwrt/luci applications/luci-app-upnp
git_sparse_clone master https://github.com/immortalwrt/luci applications/luci-app-wol

# 更新 Argon 主题
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config

# ==========================================
# 5. 更新并安装包源
# ==========================================
./scripts/feeds update -a
./scripts/feeds install -a
