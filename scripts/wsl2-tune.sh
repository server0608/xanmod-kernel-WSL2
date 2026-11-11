#!/bin/bash
# WSL2 Linux Guest Environment Optimizer
# Tailored for High-Performance Development (Android / Linux Kernel / Node.js)

set -e

if [ "$EUID" -ne 0 ]; then
  echo "[-] 请使用 sudo 权限执行此脚本: sudo $0"
  exit 1
fi

echo "[+] 1. 清理闲置/耗时的后台 Systemd 系统服务..."
SERVICES_TO_DISABLE=(
  snapd.service snapd.socket snapd.seeded.service snapd.snap-repair.timer
  landscape-client.service
  wsl-pro.service
  motd-news.timer motd-news.service
  apport.service apport-autoreport.path apport-autoreport.service apport-autoreport.timer apport-forward.socket
)

for s in "${SERVICES_TO_DISABLE[@]}"; do
  systemctl disable --now "$s" 2>/dev/null || true
done
systemctl mask snapd.service snapd.socket wsl-pro.service 2>/dev/null || true
echo "    -> 已停用并屏蔽 snapd, wsl-pro, landscape, motd-news, apport 等冗余服务。"

echo "[+] 2. 配置开发环境 sysctl 内核参数 (/etc/sysctl.d/99-wsl-tune.conf)..."
cat << 'EOF' > /etc/sysctl.d/99-wsl-tune.conf
# WSL 开发环境调优（高并发 / 大工程文件监听）
fs.inotify.max_user_watches = 1048576
fs.inotify.max_user_instances = 1024
fs.inotify.max_queued_events = 65536

# 本地网络并发与连接队列
net.core.somaxconn = 4096
net.ipv4.tcp_max_syn_backlog = 8192
net.core.netdev_max_backlog = 16384

# 内存充足时降低换出倾向
vm.swappiness = 10
EOF
sysctl -p /etc/sysctl.d/99-wsl-tune.conf >/dev/null
echo "    -> sysctl 参数已生效。"

echo "[+] 3. 规范 Windows 盘挂载参数 (/etc/wsl.conf)..."
if ! grep -q "\[automount\]" /etc/wsl.conf 2>/dev/null; then
  cat << 'EOF' >> /etc/wsl.conf

[automount]
enabled=true
mountFsTab=true
options="metadata,uid=1000,gid=1000,umask=022,fmask=011"
EOF
  echo "    -> 已添加 DrvFS metadata 与权限映射参数至 /etc/wsl.conf。"
else
  echo "    -> /etc/wsl.conf 已经配置过 [automount]，跳过。"
fi

echo "[+] 4. 优化 Git 大仓库处理性能..."
if command -v git &>/dev/null; then
  REAL_USER="${SUDO_USER:-$USER}"
  sudo -u "$REAL_USER" git config --global feature.manyFiles true 2>/dev/null || true
  sudo -u "$REAL_USER" git config --global core.fsmonitor true 2>/dev/null || true
  echo "    -> Git feature.manyFiles 和 core.fsmonitor 已配置。"
fi

echo ""
echo "========================================================"
echo "[✓] WSL2 内部优化全部完成！"
echo ""
echo "宿主 Windows 建议配置 (文件路径: %UserProfile%\\.wslconfig):"
echo "--------------------------------------------------------"
echo "[wsl2]"
echo "networkingMode=mirrored"
echo "dnsTunneling=true"
echo "firewall=false"
echo "autoProxy=true"
echo "kernel=D:\\\\Software\\\\bzImage-zen5"
echo "kernelModules=D:\\\\Software\\\\bzImage-zen5-addons.vhdx"
echo ""
echo "[experimental]"
echo "hostAddressLoopback=true"
echo "autoMemoryReclaim=gradual"
echo "sparseVhd=true"
echo "========================================================"
