# xanmod-kernel-WSL2 (Zen 5 & Extreme Performance Edition)

[![Release](https://img.shields.io/github/v/release/server0608/xanmod-kernel-WSL2?color=emerald)](https://github.com/server0608/xanmod-kernel-WSL2/releases)
[![License](https://img.shields.io/github/license/server0608/xanmod-kernel-WSL2)](LICENSE)
[![Kernel Version](https://img.shields.io/badge/Kernel-7.3.4--xanmod1-blue)](https://github.com/server0608/xanmod-kernel-WSL2/releases)
[![Target CPU](https://img.shields.io/badge/Architecture-AMD%20Zen%205%20%7C%20Zen%204%2F3%20%7C%20x64v3-brightgreen)](https://github.com/server0608/xanmod-kernel-WSL2)

专为 **Windows Subsystem for Linux 2 (WSL2)** 深度定制的高性能 [XanMod](https://gitlab.com/xanmod/linux) 优化内核。原生支持 **AMD Ryzen 9000 (Zen 5)** 架构，并在本地纯开发场景下彻底解开 CPU 投机执行漏洞安全补丁（Zero-Mitigations），实现极致计算吞吐。

---

## 🌟 核心特性

- **Zen 5 原生指令集优化**：针对 AMD Ryzen 9000 系列开启 `-march=znver5`，充分释放 Zen 5 的原生 512-bit AVX-512、双倍指令分派宽度与全新分支预测模型。
- **极致吞吐 (Zero-Mitigations)**：针对本地单机沙箱开发环境，彻底剥离 `VERW` / `CLEAR_CPU_BUFFERS` 寄存器清空与 `STIBP` / `Retpoline` 等安全补丁分支，单次系统调用耗时从 343ns 骤降至 53ns。
- **透明大页全速模式 (THP Always)**：内核级开启 `TRANSPARENT_HUGEPAGE_TMPFS_HUGE_ALWAYS`，内存盘与临时文件 4K 同步 IOPS 冲破 **212 万**。
- **极速编译与调度优化**：采用 Clang + **ThinLTO**（跨模块链接期优化）与 **Polly** 循环向量化器，内核时钟中断定为 **1000Hz**，预抢占模型采用 `PREEMPT_DYNAMIC` / `PREEMPT_LAZY`。
- **网络与 GPU 满血支持**：默认集成 **BBR** 拥塞控制算法，包含微软官方最新 **dxgkrnl** DirectX GPU 直通驱动补丁及 Hyper-V 增强支持。

---

## 📊 性能实测天梯榜 (AMD Ryzen 7 9700X)

实测数据对比（微软官方原版 vs XanMod 7.2 vs **Zen 5 满血定制版**）：

![WSL2 Zen5 Benchmark](assets/benchmark_comparison.png)

| 评测项 (Benchmark) | 微软官方原版 (6.18) | XanMod 7.2 (Zen 3) | XanMod 7.2 (历史最高) | **Zen 5 满血版 (本内核)** | **较 7.2 历史最高提升** |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **系统调用吞吐 (`syscall_rate`)** | 645 万/s | 634 万/s | 674 万/s | **1,866 万/s** | **+176.9%（近 2.8 倍！）** 🚀 |
| **上下文切换 (`ctx_switch`)** | 136 万/s | 136 万/s | 141 万/s | **447 万/s** | **+215.5%（超 3.1 倍！）** ⚡ |
| **磁盘 4K IOPS (`disk_iops`)** | 55.9 万 | 31.7 万 | 122.4 万 | **212.9 万** | **+73.9%（突破 212 万）** 🔥 |
| **进程创建速率 (`fork_rate`)** | 1,691 次/s | 2,030 次/s | 2,092 次/s | **2,886 次/s** | **+38.0% 提升** |
| **内存读写带宽 (`mem_bw`)** | 2,469 MB/s | 8,536 MB/s | 9,167 MB/s | **8,760 MB/s** | **保持极速（微软版 3.5 倍）** |
| **TCP 本地回环延迟 (`tcp_loop`)** | 543.06 μs | 539.99 μs | 517.37 μs | **506.94 μs** | **创历史最低延迟** |

---

## 🚀 安装与使用

### 1. 下载预编译产物

从本仓库的 [Releases 页面](https://github.com/server0608/xanmod-kernel-WSL2/releases) 下载最新发行版产物：
- `bzImage-zen5`：满血内核镜像文件
- `bzImage-zen5-addons.vhdx.7z`：包含外部模块与头文件的虚拟磁盘压缩包（解压得到 `.vhdx`）

将两个文件放置到 Windows 宿主任意固定目录（例如 `D:\Software\`）。

### 2. 配置 Windows 端 `%UserProfile%\.wslconfig`

编辑 Windows 用户根目录下的 `.wslconfig`（若无则新建）：

```ini
[wsl2]
networkingMode=mirrored
dnsTunneling=true
firewall=false
autoProxy=true
kernel=D:\\Software\\bzImage-zen5
kernelModules=D:\\Software\\bzImage-zen5-addons.vhdx

[experimental]
hostAddressLoopback=true
autoMemoryReclaim=gradual         # 内存自动平滑释放回 Windows
sparseVhd=true                    # 虚拟磁盘自动缩容

[general]
instanceIdleTimeout=-1
```

> **注意**：Windows 路径中的反斜杠必须双写转义（`\\`）。

### 3. 应用并生效

在 Windows PowerShell 或 CMD 中执行冷重启：

```powershell
wsl --shutdown
```

重新进入 WSL 后，验证内核版本与微架构参数：

```bash
uname -r
# 应显示: 7.3.4-locietta-WSL2-xanmod1

zcat /proc/config.gz | grep MZEN
# 应显示: CONFIG_MZEN5=y
```

---

## 🛠️ 一键 WSL 系统环境优化

除了替换内核，WSL 内部系统层也提供了配套的一键优化脚本。运行后将自动清理闲置的 Systemd 守护进程、规范 DrvFS 挂载权限、配置开发级 sysctl 参数及 Git 大仓库优化：

```bash
sudo ./scripts/wsl2-tune.sh
```

---

## 🔨 本地源码构建

如需针对其他微架构自行编译：

```bash
# 1. 安装编译依赖
sudo apt update && sudo apt install -y clang lld llvm qemu-utils jq bison flex libssl-dev libelf-dev bc cpio rsync 7zip

# 2. 拉取源码并配置（-a 指定微架构，-p 开启零防护极限性能）
./scripts/setup.sh -a MZEN5 -p --branch MAIN

# 3. 编译内核（16线程并发）
cd linux
../scripts/build.sh --branch MAIN -j16

# 4. 生成内核镜像与模块 VHDX
../scripts/post-build.sh --name bzImage-zen5
```

---

## 📜 致谢与开源协议

- [Linux Kernel](https://kernel.org/)
- [XanMod Kernel](https://xanmod.org/)
- [Microsoft WSL2-Linux-Kernel](https://github.com/microsoft/WSL2-Linux-Kernel)
- [Locietta/xanmod-kernel-WSL2](https://github.com/Locietta/xanmod-kernel-WSL2) (Upstream Port)

本项目遵循 [GPL-2.0](LICENSE) 开源协议。
