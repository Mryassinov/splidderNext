# Splidder Kernel v1.0 - Stable Release

**Release Date:** February 14, 2026  
**Device:** Redmi Note 10 Pro (sweet)  
**Android Version:** Android 13/14  
**KernelSU:** Next + SUSFS 2.0

---

## 🎉 What's New

### First Stable Release!
- Complete rewrite with professional build system
- KernelSU-Next integration with SUSFS
- Advanced root hiding for banking apps
- Performance optimizations

---

## 📱 Device Support

- ✅ **sweet** - Redmi Note 10 Pro / Mi 11 Lite

---

## 🔐 Root Features (KernelSU-Next + SUSFS)

### KernelSU-Next
- Modern kernel-based root solution
- No Magisk required
- Systemless root
- Module support

### SUSFS 2.0 (Advanced Root Hiding)
- ✅ Hide root from banking apps
- ✅ Spoof kernel uname
- ✅ Hide mount points
- ✅ Hide kstat information
- ✅ Symbol hiding
- ✅ Open redirect support
- ✅ SUS_MAP functionality

**Supported Apps:**
- Banking apps (HSBC, Chase, etc.)
- Payment apps (Google Pay, PayPal)
- Netflix, Disney+, etc.
- Pokemon GO, etc.

---

## ⚡ Performance Features

### GPU Optimizations
- ✅ **Simple GPU Algorithm** - Enhanced GPU scheduler
- ✅ Better gaming performance
- ✅ Reduced frame drops

### CPU Optimizations  
- ✅ **O3 Compiler Flags** - Maximum optimization level
- ✅ **250Hz Tick Rate** - Improved responsiveness
- ✅ Better power efficiency

### I/O Optimizations
- ✅ **BFQ Scheduler** - Better disk performance
- ✅ **EROFS Support** - Modern read-only filesystem
- ✅ **F2FS Optimizations** - Better flash storage performance

### Memory & Security
- ✅ Enhanced ZRAM
- ✅ SELinux optimizations
- ✅ Better memory management
- ✅ Security enhancements

---

## 🛠️ Kernel Configurations
```ini
# Performance
CONFIG_SIMPLE_GPU_ALGORITHM=y
CONFIG_HZ_250=y
CONFIG_IOSCHED_BFQ=y

# Filesystems
CONFIG_EROFS_FS=y
CONFIG_FSCACHE=y
CONFIG_FSCACHE_STATS=y

# Security
CONFIG_SECURITY_SELINUX_DEVELOP=y

# Namespaces & Containers
CONFIG_PID_NS=y
CONFIG_IPC_NS=y
CONFIG_POSIX_MQUEUE=y
CONFIG_SYSVIPC=y

# KernelSU
CONFIG_KSU=y
CONFIG_KSU_SUSFS=y
CONFIG_KSU_SUSFS_SUS_PATH=y
CONFIG_KSU_SUSFS_SUS_MOUNT=y
CONFIG_KSU_SUSFS_SUS_KSTAT=y
CONFIG_KSU_SUSFS_SPOOF_UNAME=y
```

---

## 📦 Downloads

### Main Release
- **Filename:** `Splidder-v1.0-sweet-KSU_NEXT.zip`
- **Size:** 18MB
- **MD5:** `[Generate with: md5sum filename.zip]`
- **SHA256:** `[Generate with: sha256sum filename.zip]`

---

## 📝 Installation Instructions

### Prerequisites
- Unlocked bootloader
- Custom recovery (TWRP/OrangeFox)
- Backup your current boot image (recommended)

### Step-by-Step Installation

#### 1. Download
- Download the kernel zip from releases
- Verify checksum (optional but recommended)

#### 2. Boot to Recovery
Power off device →
Volume Up + Power →
Wait for recovery to load

#### 3. Flash Kernel
1. Tap **Install**
2. Navigate to downloaded zip
3. Select `Splidder-v1.0-sweet-KSU_NEXT.zip`
4. Swipe to confirm flash
5. Wait for completion

#### 4. Wipe Cache (Recommended)
1. Tap **Wipe**
2. Select **Dalvik/ART Cache**
3. Swipe to wipe

#### 5. Reboot
1. Tap **Reboot System**
2. Wait for boot (first boot may take 2-3 minutes)

#### 6. Install KernelSU Manager
1. Download KernelSU Manager: https://github.com/tiann/KernelSU/releases
2. Install the APK
3. Open app to verify KernelSU is working
4. Grant root to your apps

---

## 🔧 Troubleshooting

### Bootloop after flashing?
1. Boot to recovery
2. Restore your backup boot image
3. OR flash stock boot.img from your ROM
4. Report the issue on Telegram/XDA

### KernelSU not working?
1. Check KernelSU Manager version (use latest)
2. Reboot device
3. Check `/proc/version` - should show "Splidder"
4. Check kernel version: `uname -r`

### Battery drain?
- First 2-3 charge cycles are for calibration
- Disable aggressive governors if needed
- Check wakelocks with BetterBatteryStats

---

## ⚠️ Known Issues

- None reported in stable build
- Report issues on Telegram or GitHub Issues

---

## 🔄 Reverting to Stock

### If you need to go back:

Boot to recovery
Flash your ROM's stock boot.img
Wipe cache/dalvik
Reboot


Or use your backup boot image if you made one.

---

## 📊 Build Information
Kernel Version:     5.4.x-Splidder
Build Date:         2026-02-14 23:30
Commit Hash:        22d174f9
Builder:            yassine@splidder-build
Toolchain:          Clang 20.0.0 (r547379)
Build System:       build-ultimate.sh v3.0
Compilation Time:   11m 28s

---

## 🙏 Credits & Thanks

### KernelSU & Root
- **KernelSU** - [@tiann](https://github.com/tiann)
- **KernelSU-Next** - [KernelSU-Next Team](https://github.com/KernelSU-Next)
- **SUSFS** - [@TheSillyOk](https://github.com/TheSillyOk)

### Kernel Patches
- **SimpleGPU** - ximi-mojito-test
- **DTBO Patches** - xiaomi-sm6150 team
- **LN8K Charger** - crDroid team, tbyool

### Tools & Infrastructure
- **AnyKernel3** - osm0sis
- **Build Scripts** - Custom development

### Community
- XDA Developers community
- Telegram kernel development groups
- All testers and users!

---

## 📞 Support & Community

### Get Help
- **Telegram Group:** [Your Telegram Link]
- **XDA Thread:** [Your XDA Thread]
- **GitHub Issues:** https://github.com/YOUR_USERNAME/splidderNext/issues

### Report Bugs
Please include:
- Device model
- ROM name & version
- Kernel version
- Steps to reproduce
- Logcat (if applicable)

### Donate
If you like this kernel:
- **PayPal:** [Your PayPal]
- **Ko-fi:** [Your Ko-fi]

---

## 📜 Changelog

### v1.0 (2026-02-14) - First Stable Release
- Initial stable release
- KernelSU-Next + SUSFS 2.0
- SimpleGPU Algorithm
- O3 Optimizations
- BFQ I/O Scheduler
- Professional build system

---

## 📄 License

This kernel is based on Linux Kernel (GPL-2.0)  
Custom modifications are licensed under GPL-2.0

---

## ⚡ Performance Tips

### Gaming
- Use performance governor for demanding games
- Enable GPU boost if available
- Disable battery saver during gaming

### Battery Life
- Use balanced/powersave governor
- Disable unused features
- Optimize background apps

### Daily Use
- Default settings are already optimized
- No tweaks needed for most users
- Just flash and enjoy!

---

**Enjoy your enhanced kernel! 🚀**

*Last updated: 2026-02-14*
