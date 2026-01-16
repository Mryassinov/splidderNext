# Splidder Kernel

![Kernel Version](https://img.shields.io/badge/Kernel-5.4-blue)
![Android](https://img.shields.io/badge/Android-16%20QPR1-green)
![Platform](https://img.shields.io/badge/Platform-SM6150-orange)

A custom kernel for Xiaomi devices powered by Qualcomm SM6150 (Snapdragon 732G).

## Supported Devices

| Device | Codename | Status |
|--------|----------|--------|
| Redmi Note 10 Pro | sweet | ✅ Supported |
| Redmi Note 10 Pro Max | sweet | ✅ Supported |
| Mi 10 Lite 5G | tucana | ✅ Supported |
| Mi Note 10 Lite | toco | ✅ Supported |
| Redmi K30 | phoenix | ✅ Supported |
| Mi 9T | davinci | ✅ Supported |

## Features

- ⚡ **Android 16 QPR1** - Latest Android version support
- 🔒 **January 2026 Security Patch** - Up-to-date security
- 🎵 **Dolby Audio** - Enhanced audio experience
- 📷 **MIUI Camera** - Stock Xiaomi camera support
- ⚙️ **Custom Optimizations** - Performance and battery tweaks
- 🔧 **Built with Clang r547379** - Modern compiler optimizations

## Downloads

Check the [Releases](https://github.com/Mryassinov/splidderNext/releases) page for the latest builds.

## Building from Source

### Prerequisites

```bash
# Install required packages (Ubuntu/Debian)
sudo apt update
sudo apt install git gcc-aarch64-linux-gnu gcc-arm-linux-gnueabi bc bison build-essential ccache curl flex g++-multilib gcc-multilib gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool libncurses5 libncurses5-dev libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev
```

### Clone the Repository

```bash
git clone https://github.com/Mryassinov/splidderNext.git -b splidder-16-qpr1
cd splidderNext
```

### Download Clang Toolchain

```bash
mkdir -p ~/aosp/prebuilts/clang/host/linux-x86/
cd ~/aosp/prebuilts/clang/host/linux-x86/
git clone --depth=1 https://gitlab.com/PixelOS-Releases/playgroundtc-clang.git -b 18 clang-r547379
```

### Build the Kernel

```bash
cd ~/splidderNext
./build-v2.sh -c
```

When prompted, enter your device codename (e.g., `sweet`).

The compiled kernel zip will be in the root directory as `Splidder-{device}-{date}.zip`

## Installation

### Requirements
- Unlocked bootloader
- Custom recovery (OrangeFox R11.1_7 recommended)
- MIUI 14 firmware installed

### Clean Flash (Recommended for first install)

1. Boot into recovery
2. Flash MIUI 14 firmware for your region
3. Flash `Splidder-{device}-{date}.zip`
4. Format Data
5. Reboot

### Dirty Flash (For updates)

1. Boot into recovery
2. Flash MIUI 14 firmware for your region
3. Flash `Splidder-{device}-{date}.zip`
4. Reboot

### Recommended Recovery

Download: [OrangeFox R11.1_7 (EROFS)](https://github.com/basamaryan/android_device_xiaomi_sweet-TWRP/releases/download/R11.1_7/OrangeFox-R11.1_7-Unofficial-sweet-EROFSCompression.zip)

## Credits

- **Kernel Maintainer**: [Mryassinov](https://github.com/Mryassinov)
- **Original Source**: [Musafir02](https://github.com/Musafir02/kernel_xiaomi_sm6150)
- **AnyKernel3**: [Basamaryan](https://github.com/basamaryan/AnyKernel3)
- **Clang Toolchain**: [PixelOS](https://gitlab.com/PixelOS-Releases)

## Support

- **XDA Thread**: [Coming Soon]
- **Telegram Group**: [Coming Soon]
- **Issues**: [GitHub Issues](https://github.com/Mryassinov/splidderNext/issues)

## License

This project is licensed under the GPL-2.0 License - see the [COPYING](COPYING) file for details.

## Disclaimer

⚠️ **Flash at your own risk!** I am not responsible for bricked devices, dead SD cards, thermonuclear war, or you getting fired because the alarm app failed. Please ensure you have backed up your data before flashing.

---

**Made with ❤️ for the SM6150 community**
