#!/bin/bash
# DIY脚本
# https://github.com/P3TERX/Actions-OpenWrt
# 文件名: diy-part1.sh
# 功能说明: OpenWrt DIY脚本第1部分（更新feeds之前）
# 版权: (c) 2019-2024 P3TERX <https://p3terx.com>
# 基于 MIT 开源协议，详见 /LICENSE

# 取消注释一个源
# sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# 添加第三方 feed 源（small-package 包含 openclash/passwall/ssr-plus 等常用插件）
echo 'src-git smpackage https://github.com/kenzok8/small-package' >> feeds.conf.default
# 添加第三方源，iStore 应用商店，编译时包名输入 luci-app-store
echo 'src-git store https://github.com/linkease/istore.git;main' >> feeds.conf.default


# OpenClash代理
# git clone --depth 1 https://github.com/vernesong/OpenClash.git OpenClash

# turboacc网络加速（需要用户在页面选择 luci-app-turboacc 后，由编译脚本自动执行，此处不再无条件运行）
# curl -sSL https://raw.githubusercontent.com/mufeng05/turboacc/main/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh

# 调试
# sed -i 's|src-git-full openstick https://github.com/lkiuyu/openstick-feeds.git|src-git-full openstick https://github.com/xuxin1955/openstick-feeds|g' feeds.conf.default

# ============================================================
# 修补：本源码快照的 feeds 里缺少 libffi 源码包
# 现象：glib2 / python3 / ruby / wayland 等十几个包的 Makefile
#       都声明依赖 libffi，但 feeds 里搜不到它，导致
#       "Package glib2-gobject is missing dependencies ... libffi.so.8"
# 做法：从 openwrt/packages 稀疏克隆 libs/libffi 注入 package/libs/
# ============================================================
if [ ! -d package/libs/libffi ]; then
  echo "==> [patch] injecting libffi package source"
  rm -rf /tmp/owrt-pkgs
  git clone --depth 1 --filter=blob:none --sparse https://github.com/openwrt/packages.git /tmp/owrt-pkgs 2>/dev/null || true
  if [ -d /tmp/owrt-pkgs ]; then
    ( cd /tmp/owrt-pkgs && git sparse-checkout set libs/libffi 2>/dev/null || true )
  fi
  if [ -d /tmp/owrt-pkgs/libs/libffi ]; then
    mkdir -p package/libs
    cp -r /tmp/owrt-pkgs/libs/libffi package/libs/
    echo "==> [patch] libffi injected: $(ls package/libs/libffi)"
  else
    echo "==> [patch] WARNING: libffi clone failed, will likely fail later"
  fi
else
  echo "==> [patch] libffi already present"
fi