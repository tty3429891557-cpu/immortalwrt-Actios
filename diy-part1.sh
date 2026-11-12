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
# 修补：本源码快照缺少 libffi 包源
# 事实核查：
#   immortalwrt/packages  → 无 libs/libffi
#   openwrt/packages      → 无 libs/libffi
#   lkiuyu/immortalwrt@7fe583d9 → package/libs/libffi 缺失（共48项，无它）
#   openwrt/openwrt       → package/libs/libffi 存在  ← 唯一的正确来源
# 症状：glib2-gobject / python3 / ruby / wayland 等声明依赖 libffi，
#       打包时报 "Package glib2-gobject is missing dependencies ... libffi.so.8"
# ============================================================
if [ ! -d package/libs/libffi ]; then
  echo "==> [patch] injecting libffi from openwrt/openwrt core tree"
  rm -rf /tmp/owrt-core /tmp/owrt-core.tar.gz
  mkdir -p /tmp/owrt-core
  if curl -fSL --retry 3 --retry-delay 2 -o /tmp/owrt-core.tar.gz \
       https://codeload.github.com/openwrt/openwrt/tar.gz/refs/heads/main; then
    echo "==> [patch] tarball downloaded: $(stat -c%s /tmp/owrt-core.tar.gz) bytes"
    if tar xzf /tmp/owrt-core.tar.gz -C /tmp/owrt-core --strip-components=1 \
         openwrt-main/package/libs/libffi; then
      echo "==> [patch] extracted:"
      ls -la /tmp/owrt-core/package/libs/libffi || true
      mkdir -p package/libs
      cp -r /tmp/owrt-core/package/libs/libffi package/libs/
      echo "==> [patch] injected -> package/libs/libffi: $(ls package/libs/libffi)"
      head -5 package/libs/libffi/Makefile || true
    else
      echo "==> [patch] ERROR: tar extraction failed"
    fi
  else
    echo "==> [patch] ERROR: download failed"
  fi
else
  echo "==> [patch] libffi already present at package/libs/libffi"
fi

# 校验：符号是否会被 defconfig 认出
if [ -d package/libs/libffi ]; then
  echo "==> [patch] OK libffi source present"
else
  echo "==> [patch] FAILED libffi still missing —— 编译大概率在 glib2 处失败"
fi