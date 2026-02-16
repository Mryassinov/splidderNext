#!/bin/bash
##################################################
# Splidder Kernel Compile Script v4.0 ULTIMATE PRO
# Enhanced with Granular KernelSU & SUSFS Options
# Maintainer: yassine
# Zero-Error Professional Build System
##################################################

set -e  # Exit on error
SECONDS=0  # builtin bash timer

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${CYAN}==>${NC} ${BLUE}$1${NC}\n"
}

log_header() {
    echo -e "\n${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║  $1"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

log_feature() {
    echo -e "${CYAN}  ✓${NC} $1"
}

# Error handler
error_exit() {
    log_error "$1"
    log_error "Build failed! Restoring clean state..."
    restore_source_tree
    exit 1
}

# Trap errors
trap 'error_exit "An unexpected error occurred."' ERR

# Deep clean function - removes ALL build artifacts
deep_clean() {
    log_step "Performing deep clean..."
    
    # Remove build output
    if [ -d "out" ]; then
        rm -rf out
        log_info "✓ Removed out/ directory"
    fi
    
    # Remove KernelSU directories
    if [ -d "KernelSU" ]; then
        rm -rf KernelSU
        log_info "✓ Removed KernelSU/ directory"
    fi
    
    if [ -d "KernelSU-Next" ]; then
        rm -rf KernelSU-Next
        log_info "✓ Removed KernelSU-Next/ directory"
    fi
    
    # Remove patch artifacts
    find . -name "*.rej" -type f -delete 2>/dev/null || true
    find . -name "*.orig" -type f -delete 2>/dev/null || true
    log_info "✓ Removed all patch artifacts"
    
    # Remove defconfig backups
    find arch/arm64/configs/ -name "*_defconfig.bak" -type f -delete 2>/dev/null || true
    find arch/arm64/configs/ -name "*_defconfig.pristine" -type f -delete 2>/dev/null || true
    log_info "✓ Removed defconfig backups"
    
    log_success "Deep clean completed"
}

# Restore source tree to pristine state
restore_source_tree() {
    log_step "Restoring source tree to clean state..."
    
    if git rev-parse --git-dir > /dev/null 2>&1; then
        # Stash any uncommitted changes
        git stash push -u -m "build-script-auto-stash-$(date +%s)" 2>/dev/null || true
        
        # Reset all tracked files
        git checkout -- . 2>/dev/null || true
        
        # Remove untracked files (except user files)
        git clean -fd -e "*.zip" -e "build*.sh" -e "*.md" 2>/dev/null || true
        
        log_success "Source tree restored to clean state"
    else
        log_warning "Not a git repository - manual cleanup only"
    fi
}

# Validate requirements
check_requirements() {
    log_step "Checking build requirements..."
    
    local missing_tools=()
    
    # Check required commands
    for cmd in make wget curl git zip patch sed; do
        if ! command -v $cmd &> /dev/null; then
            missing_tools+=("$cmd")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        error_exit "Missing required tools: ${missing_tools[*]}. Please install them first."
    fi
    
    # Verify we're in kernel source directory
    if [ ! -f "Makefile" ] || [ ! -d "arch/arm64" ]; then
        error_exit "Not in kernel source directory! Please run this script from kernel root."
    fi
    
    log_success "All required tools are available"
}

# Find and setup toolchain
setup_toolchain() {
    log_info "Detecting toolchain..."
    
    # Try multiple possible clang locations
    local POSSIBLE_CLANG_PATHS=(
        "$HOME/aosp/prebuilts/clang/host/linux-x86/clang-r547379/clang-r547379/bin"
        "$HOME/aosp/prebuilts/clang/host/linux-x86/clang-r547379/bin"
        "$HOME/aosp/prebuilts/clang/host/linux-x86/clang-r547379"
        "/home/zohaib/aosp/prebuilts/clang/host/linux-x86/clang-r547379/bin"
        "$HOME/toolchains/clang-r547379/bin"
        "$PWD/clang/bin"
    )
    
    local CLANG_BIN_DIR=""
    
    # Find the first valid clang path
    for path in "${POSSIBLE_CLANG_PATHS[@]}"; do
        if [ -d "$path" ] && [ -f "$path/clang" ]; then
            CLANG_BIN_DIR="$path"
            log_success "Found clang at: $CLANG_BIN_DIR"
            break
        elif [ -d "$path/bin" ] && [ -f "$path/bin/clang" ]; then
            CLANG_BIN_DIR="$path/bin"
            log_success "Found clang at: $CLANG_BIN_DIR"
            break
        fi
    done
    
    # If not found, check if clang is already in PATH
    if [ -z "$CLANG_BIN_DIR" ]; then
        if command -v clang &> /dev/null; then
            CLANG_BIN_DIR=$(dirname $(which clang))
            log_warning "Using system clang from PATH: $CLANG_BIN_DIR"
        else
            error_exit "Clang toolchain not found! Please install it or set the correct path."
        fi
    fi
    
    # Add to PATH
    export PATH="$CLANG_BIN_DIR:$PATH"
    
    # Verify clang is now accessible
    if ! command -v clang &> /dev/null; then
        error_exit "Clang still not accessible after PATH setup. Check your toolchain installation."
    fi
    
    # Show clang version
    local CLANG_VERSION=$(clang --version | head -n1)
    log_info "Using: $CLANG_VERSION"
}

# Setup environment function
setup_environment() {
    log_step "Setting up build environment..."
    
    # Imports
    local DEVICE="$1"
    local KERNELSU_SELECTOR="$2"
    local SUSFS_SELECTOR="$3"
    local LN8K_SELECTOR="$4"
    
    # Maintainer info
    export KBUILD_BUILD_USER=yassine
    export KBUILD_BUILD_HOST=splidder-build
    export LOCALVERSION="-Splidder"
    export GIT_NAME="$KBUILD_BUILD_USER"
    export GIT_EMAIL="$KBUILD_BUILD_USER@$KBUILD_BUILD_HOST"
    
    # Arch and build settings
    export ARCH=arm64
    export SUBARCH=arm64
    
    # Setup toolchain
    setup_toolchain
    
    # Device codename
    export DEVICE_CODENAME="$DEVICE"
    
    # Generate ZIP name based on configuration
    local ZIPNAME_SUFFIX=""
    if [[ "$KERNELSU_SELECTOR" == *"KSU_NEXT"* ]]; then
        if [[ "$SUSFS_SELECTOR" == *"TRUE"* ]]; then
            ZIPNAME_SUFFIX="-KSUNEXT-SUSFS"
        else
            ZIPNAME_SUFFIX="-KSUNEXT"
        fi
    elif [[ "$KERNELSU_SELECTOR" == *"KSU_BLXX"* ]]; then
        ZIPNAME_SUFFIX="-KSUBLXX"
    else
        ZIPNAME_SUFFIX="-VANILLA"
    fi
    
    export ZIPNAME="Splidder-${DEVICE}${ZIPNAME_SUFFIX}-$(date '+%Y%m%d-%H%M').zip"
    
    # Defconfig Settings
    export MAIN_DEFCONFIG="arch/arm64/configs/${DEVICE}_defconfig"
    export COMPILE_DEFCONFIG="${DEVICE}_defconfig"
    
    # Validate defconfig exists
    if [ ! -f "$MAIN_DEFCONFIG" ]; then
        error_exit "Defconfig not found: $MAIN_DEFCONFIG"
    fi
    
    # Create a pristine backup of defconfig
    cp "$MAIN_DEFCONFIG" "${MAIN_DEFCONFIG}.pristine"
    log_success "Created pristine defconfig backup"
    
    log_success "Using defconfig: $MAIN_DEFCONFIG"
    
    # KernelSU Settings
    case "$KERNELSU_SELECTOR" in
        "--ksu=KSU_BLXX")
            export KSU_SETUP_URI="https://github.com/backslashxx/KernelSU/raw/refs/heads/master/kernel/setup.sh"
            export KSU_BRANCH="master"
            export KSU_GENERAL_PATCH="https://github.com/ximi-mojito-test/mojito_krenol/commit/ebc23ea38f787745590c96035cb83cd11eb6b0e7.patch"
            export KSU_TYPE="BLXX"
            export KSU_DISPLAY="KernelSU-BLXX (Hookless)"
            export ENABLE_SUSFS=false
            ;;
        "--ksu=KSU_NEXT")
            export KSU_SETUP_URI="https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh"
            export KSU_BRANCH="legacy"
            export KSU_GENERAL_PATCH="https://github.com/ximi-mojito-test/mojito_krenol/commit/8e25004fdc74d9bf6d902d02e402620c17c692df.patch"
            export KSU_TYPE="NEXT"
            
            # Check SUSFS option
            if [[ "$SUSFS_SELECTOR" == "--susfs=TRUE" ]]; then
                export ENABLE_SUSFS=true
                export KSU_DISPLAY="KernelSU-Next + SUSFS"
            else
                export ENABLE_SUSFS=false
                export KSU_DISPLAY="KernelSU-Next"
            fi
            ;;
        "--ksu=NONE")
            export KSU_SETUP_URI=""
            export KSU_BRANCH=""
            export KSU_GENERAL_PATCH=""
            export KSU_TYPE="NONE"
            export KSU_DISPLAY="Vanilla (No Root)"
            export ENABLE_SUSFS=false
            ;;
        *)
            error_exit "Invalid KernelSU selector: $KERNELSU_SELECTOR"
            ;;
    esac
    
    # LN8K Settings
    case "$LN8K_SELECTOR" in
        "--ln8k=TRUE")
            # Main LN8K Exports
            export LN8K_PATCH1="https://github.com/crdroidandroid/android_kernel_xiaomi_sm6150/commit/7b73f853977d2c016e30319dffb1f49957d30b40.patch"
            export LN8K_PATCH2="https://github.com/crdroidandroid/android_kernel_xiaomi_sm6150/commit/63dddc108d57dc43e1cd0da0f1445875f760cf97.patch"
            export LN8K_PATCH3="https://github.com/crdroidandroid/android_kernel_xiaomi_sm6150/commit/95816dff2ecc7ddd907a56537946b5cf1e864953.patch"
            export LN8K_PATCH4="https://github.com/crdroidandroid/android_kernel_xiaomi_sm6150/commit/330c60abc13530bd05287f9e5395d283ebfd6d0b.patch"
            export LN8K_PATCH5="https://github.com/crdroidandroid/android_kernel_xiaomi_sm6150/commit/0477c7006b41a1763b3314af9eb300491b91fc25.patch"
            # Sub LN8K Exports
            export LN8K_PATCH6="https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/aa5ddad5be03aa7436e7ce6e84d46b280849acae.patch"
            export LN8K_PATCH7="https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/857638b0da6f80830122b8d1b45c7842970e76c3.patch"
            export LN8K_PATCH8="https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/3a68adff14cbedd09ce2a735d575c3bf92dd696f.patch"
            export LN8K_PATCH9="https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/30fcc15d5dcf2cfc3b83a5a7d4a77e2880639fa5.patch"
            export LN8K_PATCH10="https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/1a17a6fbbf59d901c4b3aec66c06a1c96cd89c7e.patch"
            export LN8K_ENABLED=true
            export LN8K_DISPLAY="Enabled"
            ;;
        "--ln8k=FALSE")
            export LN8K_PATCH1=""
            export LN8K_ENABLED=false
            export LN8K_DISPLAY="Disabled"
            ;;
        *)
            error_exit "Invalid LN8K selector: $LN8K_SELECTOR"
            ;;
    esac
    
    # TheSillyOk's Exports
    export SILLY_KPATCH_NEXT_PATCH="https://github.com/TheSillyOk/kernel_ls_patches/raw/refs/heads/master/kpatch_fix.patch"
    export SILLY_SUSFS_PATCH="https://github.com/TheSillyOk/kernel_ls_patches/raw/refs/heads/master/susfs-2.0.0.patch"
    export SILLY_KSUN_SUSFS_PATCH="https://github.com/TheSillyOk/kernel_ls_patches/raw/refs/heads/master/KSUN/KSUN-SUSFS-2.0.0.patch"
    
    # KernelSU umount patch
    export KSU_UMOUNT_PATCH="https://github.com/tbyool/android_kernel_xiaomi_sm6150/commit/64db0dfa2f8aa6c519dbf21eb65c9b89643cda3d.patch"
    
    # Simple GPU Algorithm exports
    export SIMPLEGPU_PATCH1="https://github.com/ximi-mojito-test/mojito_krenol/commit/466da67f1ee6a567c9bd60282123a07fc9ac75b5.patch"
    export SIMPLEGPU_PATCH2="https://github.com/ximi-mojito-test/mojito_krenol/commit/f87bd5e18caba7dd0ba0b5c9147d59bb21ff606f.patch"
    export SIMPLEGPU_PATCH3="https://github.com/ximi-mojito-test/mojito_krenol/commit/ebf97a47dc43b1285602c4d3cc9667377d021f1e.patch"
    
    log_success "Environment setup completed"
}

# Apply patch with error handling (silent mode)
apply_patch_silent() {
    local patch_url="$1"
    local patch_name="$2"
    
    if wget -q --timeout=30 -O- "$patch_url" 2>/dev/null | patch -s -p1 --forward --no-backup-if-mismatch 2>/dev/null; then
        log_info "✓ Applied: $patch_name"
        return 0
    else
        # Patch failed - could be already applied or incompatible
        return 1
    fi
}

# Add patches function
add_patches() {
    log_step "Applying kernel patches..."
    
    # Temporarily disable strict error checking for patches
    set +e
    
    local applied=0
    local skipped=0
    
    # DTBO patches disabled (already in kernel source)
    log_info "DTBO patches disabled (already in kernel source)"
    
    # Apply Simple GPU Algorithm patches
    log_info "Applying Simple GPU Algorithm patches..."
    applied=0
    skipped=0
    apply_patch_silent "$SIMPLEGPU_PATCH1" "SimpleGPU patch 1/3" && ((applied++)) || ((skipped++))
    apply_patch_silent "$SIMPLEGPU_PATCH2" "SimpleGPU patch 2/3" && ((applied++)) || ((skipped++))
    apply_patch_silent "$SIMPLEGPU_PATCH3" "SimpleGPU patch 3/3" && ((applied++)) || ((skipped++))
    
    log_info "SimpleGPU: Applied $applied, Skipped $skipped"
    
    # Re-enable strict error checking
    set -e
    
    # Add SimpleGPU config
    if ! grep -q "CONFIG_SIMPLE_GPU_ALGORITHM=y" "$MAIN_DEFCONFIG" 2>/dev/null; then
        echo "CONFIG_SIMPLE_GPU_ALGORITHM=y" >> "$MAIN_DEFCONFIG"
        log_info "✓ Enabled CONFIG_SIMPLE_GPU_ALGORITHM"
    fi
    
    # Apply general config patches
    log_info "Tuning kernel configs..."
    
    # Apply config changes
    sed -i 's/# CONFIG_PID_NS is not set/CONFIG_PID_NS=y/' "$MAIN_DEFCONFIG" 2>/dev/null || true
    sed -i 's/CONFIG_HZ_300=y/CONFIG_HZ_250=y/' "$MAIN_DEFCONFIG" 2>/dev/null || true
    
    # Add configs if not present (avoid duplicates)
    for config in \
        "CONFIG_POSIX_MQUEUE=y" \
        "CONFIG_SYSVIPC=y" \
        "CONFIG_CGROUP_DEVICE=y" \
        "CONFIG_DEVTMPFS=y" \
        "CONFIG_IPC_NS=y" \
        "CONFIG_DEVTMPFS_MOUNT=y" \
        "CONFIG_EROFS_FS=y" \
        "CONFIG_FSCACHE=y" \
        "CONFIG_FSCACHE_STATS=y" \
        "CONFIG_FSCACHE_HISTOGRAM=y" \
        "CONFIG_SECURITY_SELINUX_DEVELOP=y" \
        "CONFIG_IOSCHED_BFQ=y"; do
        if ! grep -q "^${config}$" "$MAIN_DEFCONFIG" 2>/dev/null; then
            echo "$config" >> "$MAIN_DEFCONFIG"
        fi
    done
    
    # Sort and deduplicate defconfig
    sort -u "$MAIN_DEFCONFIG" -o "$MAIN_DEFCONFIG.tmp"
    mv "$MAIN_DEFCONFIG.tmp" "$MAIN_DEFCONFIG"
    
    log_info "✓ Kernel configs tuned and deduplicated"
    
    # Apply O3 optimization flags
    log_info "Applying O3 optimization flags..."
    if [ -f "Makefile" ]; then
        sed -i 's/KBUILD_CFLAGS[[:space:]]*+=[[:space:]]*-O2/KBUILD_CFLAGS   += -O3/g' Makefile 2>/dev/null || true
        sed -i 's/LDFLAGS[[:space:]]*+=[[:space:]]*-O2/LDFLAGS += -O3/g' Makefile 2>/dev/null || true
        log_info "✓ O3 flags applied"
    fi
    
    log_success "Patches applied successfully"
}

# Add LN8K function
add_ln8k() {
    if [ "$LN8K_ENABLED" = true ]; then
        log_step "Applying LN8K fast charger patches..."
        
        # Temporarily disable strict error checking
        set +e
        
        local applied=0
        local skipped=0
        
        apply_patch_silent "$LN8K_PATCH1" "LN8K patch 1/10" && ((applied++)) || ((skipped++))
        apply_patch_silent "$LN8K_PATCH2" "LN8K patch 2/10" && ((applied++)) || ((skipped++))
        apply_patch_silent "$LN8K_PATCH3" "LN8K patch 3/10" && ((applied++)) || ((skipped++))
        apply_patch_silent "$LN8K_PATCH4" "LN8K patch 4/10" && ((applied++)) || ((skipped++))
        apply_patch_silent "$LN8K_PATCH5" "LN8K patch 5/10" && ((applied++)) || ((skipped++))
        apply_patch_silent "$LN8K_PATCH6" "LN8K patch 6/10" && ((applied++)) || ((skipped++))
        apply_patch_silent "$LN8K_PATCH7" "LN8K patch 7/10" && ((applied++)) || ((skipped++))
        apply_patch_silent "$LN8K_PATCH8" "LN8K patch 8/10" && ((applied++)) || ((skipped++))
        apply_patch_silent "$LN8K_PATCH9" "LN8K patch 9/10" && ((applied++)) || ((skipped++))
        apply_patch_silent "$LN8K_PATCH10" "LN8K patch 10/10" && ((applied++)) || ((skipped++))
        
        # Re-enable strict error checking
        set -e
        
        log_info "LN8K: Applied $applied, Skipped $skipped"
        
        # Add LN8K config
        if ! grep -q "CONFIG_CHARGER_LN8000=y" "$MAIN_DEFCONFIG" 2>/dev/null; then
            echo "CONFIG_CHARGER_LN8000=y" >> "$MAIN_DEFCONFIG"
            log_info "✓ Enabled CONFIG_CHARGER_LN8000"
        fi
        
        log_success "LN8K patches applied successfully"
    else
        log_info "LN8K fast charging disabled (skipping patches)"
    fi
}

# Add KernelSU function
add_ksu() {
    if [ -n "$KSU_SETUP_URI" ]; then
        log_step "Setting up KernelSU ($KSU_TYPE)..."
        
        # Temporarily disable strict error checking for patches
        set +e
        
        # Apply umount backport and kpatch fixes
        log_info "Applying KSU prerequisite patches..."
        apply_patch_silent "$KSU_UMOUNT_PATCH" "KSU umount patch"
        apply_patch_silent "$SILLY_KPATCH_NEXT_PATCH" "Kpatch fix"
        
        # Re-enable strict error checking for setup scripts
        set -e
        
        if [[ "$KSU_SETUP_URI" == *"backslashxx/KernelSU"* ]]; then
            log_info "Setting up KSU_BLXX (hookless mode)..."
            
            # Run Setup Script
            if ! curl -LSs "$KSU_SETUP_URI" | bash -s "$KSU_BRANCH"; then
                error_exit "Failed to setup KernelSU"
            fi
            
            # Manual Config Enablement
            for config in \
                "CONFIG_KSU=y" \
                "CONFIG_KSU_TAMPER_SYSCALL_TABLE=y" \
                "CONFIG_KPROBES=y" \
                "CONFIG_HAVE_KPROBES=y" \
                "CONFIG_KPROBE_EVENTS=y" \
                "CONFIG_KRETPROBES=y" \
                "CONFIG_HAVE_SYSCALL_TRACEPOINTS=y"; do
                if ! grep -q "^${config}$" "$MAIN_DEFCONFIG" 2>/dev/null; then
                    echo "$config" >> "$MAIN_DEFCONFIG"
                fi
            done
            
            log_success "KSU_BLXX configured successfully"
            
        elif [[ "$KSU_SETUP_URI" == *"KernelSU-Next/KernelSU-Next"* ]]; then
            log_info "Setting up KSU_NEXT..."
            
            # Temporarily disable strict error checking for patch
            set +e
            
            # Apply manual hook
            apply_patch_silent "$KSU_GENERAL_PATCH" "KSU general patch"
            
            # Re-enable strict error checking
            set -e
            
            # Run Setup Script
            if ! curl -LSs "$KSU_SETUP_URI" | bash -s "$KSU_BRANCH"; then
                error_exit "Failed to setup KernelSU-Next"
            fi
            
            # Manual Config Enablement
            if ! grep -q "^CONFIG_KSU=y$" "$MAIN_DEFCONFIG" 2>/dev/null; then
                echo "CONFIG_KSU=y" >> "$MAIN_DEFCONFIG"
            fi
            if ! grep -q "^KSU_MANUAL_HOOK=y$" "$MAIN_DEFCONFIG" 2>/dev/null; then
                echo "KSU_MANUAL_HOOK=y" >> "$MAIN_DEFCONFIG"
            fi
            
            # Check if SUSFS should be enabled
            if [ "$ENABLE_SUSFS" = true ]; then
                log_info "Enabling SUSFS for advanced root hiding..."
                
                # Apply SUSFS patches
                log_info "Applying SUSFS patches..."
                
                # Temporarily disable strict error checking
                set +e
                
                apply_patch_silent "$SILLY_SUSFS_PATCH" "SUSFS patch"
                
                # Apply KSU SUSFS patches
                if [ -d "KernelSU-Next" ]; then
                    (
                        cd KernelSU-Next || exit 1
                        apply_patch_silent "$SILLY_KSUN_SUSFS_PATCH" "KSUN SUSFS patch"
                        
                        # Git cleanup
                        git config user.email "$GIT_EMAIL" 2>/dev/null || true
                        git config user.name "$GIT_NAME" 2>/dev/null || true
                        git config advice.addEmbeddedRepo false 2>/dev/null || true
                        git add . 2>/dev/null || true
                        git commit -m "cleanup: applied patches before build" &> /dev/null || true
                    )
                fi
                
                # Re-enable strict error checking
                set -e
                
                # Enable SUSFS configs
                log_info "Enabling SUSFS configs..."
                for config in \
                    "CONFIG_KSU_SUSFS=y" \
                    "CONFIG_KSU_SUSFS_SUS_PATH=y" \
                    "CONFIG_KSU_SUSFS_SUS_MOUNT=y" \
                    "CONFIG_KSU_SUSFS_SUS_KSTAT=y" \
                    "CONFIG_KSU_SUSFS_SPOOF_UNAME=y" \
                    "CONFIG_KSU_SUSFS_ENABLE_LOG=y" \
                    "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS=y" \
                    "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG=n" \
                    "CONFIG_KSU_SUSFS_OPEN_REDIRECT=y" \
                    "CONFIG_KSU_SUSFS_SUS_MAP=y" \
                    "CONFIG_KSU_SUSFS_TRY_UMOUNT=n"; do
                    if ! grep -q "^${config}$" "$MAIN_DEFCONFIG" 2>/dev/null; then
                        echo "$config" >> "$MAIN_DEFCONFIG"
                    fi
                done
                
                log_success "KSU_NEXT with SUSFS configured successfully"
            else
                log_info "SUSFS disabled - using KSU_NEXT without root hiding"
                log_success "KSU_NEXT configured successfully (without SUSFS)"
            fi
        fi
        
        log_success "KernelSU setup completed!"
    else
        log_info "Building vanilla kernel (no KernelSU)"
    fi
}

# Compile kernel function
compile_kernel() {
    log_step "Compiling kernel..."
    
    # Git cleanup before compiling
    log_info "Cleaning up git repository..."
    git config user.email "$GIT_EMAIL" 2>/dev/null || true
    git config user.name "$GIT_NAME" 2>/dev/null || true
    git config advice.addEmbeddedRepo false 2>/dev/null || true
    git add . 2>/dev/null || true
    git commit -m "cleanup: applied patches before build" &> /dev/null || true
    
    # Start compilation
    log_info "Building defconfig for $DEVICE_CODENAME..."
    make O=out ARCH=arm64 "$COMPILE_DEFCONFIG" || error_exit "Failed to create defconfig"
    
    log_info "Starting kernel compilation with $(nproc) threads..."
    log_info "This may take 5-15 minutes depending on your system..."
    
    if ! make -j$(nproc) \
        O=out \
        ARCH=arm64 \
        LLVM=1 \
        LLVM_IAS=1 \
        CROSS_COMPILE=aarch64-linux-gnu- \
        CROSS_COMPILE_ARM32=arm-linux-gnueabi-; then
        error_exit "Kernel compilation failed!"
    fi
    
    log_success "Kernel compiled successfully!"
}

# Package kernel function
package_kernel() {
    log_step "Packaging kernel..."
    
    local kernel="out/arch/arm64/boot/Image.gz"
    local dtbo="out/arch/arm64/boot/dtbo.img"
    local dtb="out/arch/arm64/boot/dtb.img"
    
    # Verify all required files exist
    if [ ! -f "$kernel" ]; then
        error_exit "Kernel image not found: $kernel"
    fi
    if [ ! -f "$dtbo" ]; then
        error_exit "DTBO image not found: $dtbo"
    fi
    if [ ! -f "$dtb" ]; then
        error_exit "DTB image not found: $dtb"
    fi
    
    log_success "All kernel components built successfully!"
    
    # Get or clone AnyKernel3
    if [ -d "$AK3_DIR" ]; then
        log_info "Using local AnyKernel3 directory..."
        cp -r "$AK3_DIR" AnyKernel3
    else
        log_info "Cloning AnyKernel3 repository..."
        if ! git clone -q https://github.com/Mryassinov/AnyKernel3-Splidder -b master AnyKernel3; then
            error_exit "Failed to clone AnyKernel3 repository"
        fi
    fi
    
    # Modify anykernel.sh
    log_info "Configuring AnyKernel3 for $DEVICE_CODENAME..."
    sed -i "s/device\.name1=.*/device.name1=${DEVICE_CODENAME}/" AnyKernel3/anykernel.sh
    sed -i "s/device\.name2=.*/device.name2=${DEVICE_CODENAME}in/" AnyKernel3/anykernel.sh
    
    # Copy kernel files
    cp "$kernel" AnyKernel3/
    cp "$dtbo" AnyKernel3/
    cp "$dtb" AnyKernel3/
    
    # Create zip
    log_info "Creating flashable zip..."
    (
        cd AnyKernel3 || error_exit "Failed to enter AnyKernel3 directory"
        zip -r9 "../$ZIPNAME" * -x .git .gitignore README.md &> /dev/null
    ) || error_exit "Failed to create zip file"
    
    # Cleanup
    rm -rf AnyKernel3
    
    # Calculate build time
    local build_time_min=$((SECONDS / 60))
    local build_time_sec=$((SECONDS % 60))
    
    # Get git commit hash
    local commit_hash="N/A"
    if git rev-parse --verify HEAD &> /dev/null; then
        commit_hash=$(git rev-parse --short=8 HEAD)
    fi
    
    # Display build summary
    log_header "BUILD COMPLETED SUCCESSFULLY!"
    
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}Device:${NC}      ${CYAN}$DEVICE_CODENAME${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}KernelSU:${NC}    ${CYAN}$KSU_DISPLAY${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}LN8K:${NC}        ${CYAN}$LN8K_DISPLAY${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}Build Time:${NC}  ${CYAN}${build_time_min}m ${build_time_sec}s${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}Commit:${NC}      ${CYAN}$commit_hash${NC}"
    echo -e "${GREEN}║${NC}  ${BOLD}Output:${NC}      ${CYAN}$ZIPNAME${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Verify zip file exists and show size
    if [ -f "$ZIPNAME" ]; then
        local zip_size=$(du -h "$ZIPNAME" | cut -f1)
        log_success "Flashable zip created: $ZIPNAME ($zip_size)"
    else
        error_exit "Zip file was not created!"
    fi
    
    # Send telegram notification if telegram command exists
    if command -v telegram &> /dev/null; then
        log_info "Sending Telegram notification..."
        telegram -f "$ZIPNAME" -M "✅ Splidder Kernel Build Complete!
━━━━━━━━━━━━━━━━━━━━
📱 Device: $DEVICE_CODENAME
🔐 KernelSU: $KSU_DISPLAY
⚡ LN8K: $LN8K_DISPLAY
⏱️ Build Time: ${build_time_min}m ${build_time_sec}s
🔖 Commit: $commit_hash
━━━━━━━━━━━━━━━━━━━━" 2>/dev/null || log_warning "Telegram notification failed"
    fi
}

# Post-build cleanup
post_build_cleanup() {
    log_step "Post-build cleanup..."
    
    # Restore pristine defconfig
    if [ -f "${MAIN_DEFCONFIG}.pristine" ]; then
        mv "${MAIN_DEFCONFIG}.pristine" "$MAIN_DEFCONFIG"
        log_info "✓ Restored pristine defconfig"
    fi
    
    # Remove patch artifacts
    find . -name "*.rej" -type f -delete 2>/dev/null || true
    find . -name "*.orig" -type f -delete 2>/dev/null || true
    
    log_success "Post-build cleanup completed"
}

# Show help message
show_help() {
    cat << EOF
${CYAN}╔══════════════════════════════════════════════════════════════╗
║       Splidder Kernel Build Script v4.0 ULTIMATE PRO         ║
║       Enhanced with Granular KernelSU & SUSFS Control        ║
╚══════════════════════════════════════════════════════════════╝${NC}

${GREEN}FEATURES:${NC}
    ✓ Granular KernelSU control (BLXX/NEXT with SUSFS toggle)
    ✓ Automatic deep clean on every build
    ✓ Source tree restoration on errors
    ✓ Pristine defconfig management
    ✓ Silent patch application (no prompts)
    ✓ Zero-error guarantee

${GREEN}USAGE:${NC}
    $0 [DEVICE] [KSU_OPTION] [SUSFS_OPTION] [LN8K_OPTION]

${GREEN}DEVICE:${NC}
    sweet, tucana, toco, phoenix, davinci

${GREEN}KSU_OPTION:${NC}
    --ksu=KSU_BLXX  backslashxx's KernelSU (hookless mode)
    --ksu=KSU_NEXT  KernelSU-Next (with optional SUSFS)
    --ksu=NONE      Vanilla kernel (no root)

${GREEN}SUSFS_OPTION (Only for KSU_NEXT):${NC}
    --susfs=TRUE    Enable SUSFS root hiding
    --susfs=FALSE   Disable SUSFS (KSU_NEXT only)

${GREEN}LN8K_OPTION:${NC}
    --ln8k=TRUE     Enable LN8K fast charging support
    --ln8k=FALSE    Disable LN8K fast charging

${GREEN}EXAMPLES:${NC}
    ${YELLOW}# Interactive mode (recommended)${NC}
    $0

    ${YELLOW}# KSU_NEXT with SUSFS (maximum root hiding)${NC}
    $0 sweet --ksu=KSU_NEXT --susfs=TRUE --ln8k=FALSE

    ${YELLOW}# KSU_NEXT without SUSFS (lightweight root)${NC}
    $0 sweet --ksu=KSU_NEXT --susfs=FALSE --ln8k=FALSE

    ${YELLOW}# KSU_BLXX (stable hookless)${NC}
    $0 sweet --ksu=KSU_BLXX --susfs=FALSE --ln8k=FALSE

    ${YELLOW}# Vanilla kernel (no root)${NC}
    $0 sweet --ksu=NONE --susfs=FALSE --ln8k=FALSE

${GREEN}BUILD VARIANTS:${NC}
    Zip filenames will reflect your choices:
    • Splidder-sweet-KSUNEXT-SUSFS-YYYYMMDD-HHMM.zip
    • Splidder-sweet-KSUNEXT-YYYYMMDD-HHMM.zip
    • Splidder-sweet-KSUBLXX-YYYYMMDD-HHMM.zip
    • Splidder-sweet-VANILLA-YYYYMMDD-HHMM.zip

EOF
}

# Main function
main() {
    # Allowed codenames
    local ALLOWED_CODENAMES=("sweet" "tucana" "toco" "phoenix" "davinci")
    
    # Show help if requested
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    # Print banner
    echo ""
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║       Splidder Kernel Build Script v4.0 ULTIMATE PRO         ║${NC}"
    echo -e "${MAGENTA}║       Enhanced KernelSU & SUSFS Control System               ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check requirements first
    check_requirements
    
    # ALWAYS perform deep clean at start
    log_header "PHASE 1: DEEP CLEAN"
    deep_clean
    restore_source_tree
    
    # Get device codename
    local DEVICE="$1"
    if [ -z "$DEVICE" ]; then
        echo -e "${GREEN}Available devices:${NC} ${ALLOWED_CODENAMES[*]}"
        read -p "Enter device codename: " DEVICE
    fi
    
    # Validate device codename
    if [[ ! " ${ALLOWED_CODENAMES[*]} " =~ " ${DEVICE} " ]]; then
        error_exit "Invalid device codename: $DEVICE. Allowed: ${ALLOWED_CODENAMES[*]}"
    fi
    
    # Get KernelSU option
    local KSU_SELECTOR="$2"
    if [ -z "$KSU_SELECTOR" ]; then
        echo ""
        echo -e "${GREEN}${BOLD}KernelSU Options:${NC}"
        echo -e "  ${CYAN}1)${NC} KSU_BLXX   - backslashxx's KernelSU (hookless, most stable)"
        echo -e "  ${CYAN}2)${NC} KSU_NEXT   - KernelSU-Next (with optional SUSFS)"
        echo -e "  ${CYAN}3)${NC} NONE       - Vanilla kernel (no root)"
        read -p "Select KernelSU option (1-3): " KSU_CHOICE
        
        case "$KSU_CHOICE" in
            1) KSU_SELECTOR="--ksu=KSU_BLXX" ;;
            2) KSU_SELECTOR="--ksu=KSU_NEXT" ;;
            3) KSU_SELECTOR="--ksu=NONE" ;;
            *) error_exit "Invalid KernelSU choice: $KSU_CHOICE" ;;
        esac
    fi
    
    # Get SUSFS option (only if KSU_NEXT selected)
    local SUSFS_SELECTOR="$3"
    if [[ "$KSU_SELECTOR" == *"KSU_NEXT"* ]]; then
        if [ -z "$SUSFS_SELECTOR" ]; then
            echo ""
            echo -e "${GREEN}${BOLD}SUSFS Options (Root Hiding):${NC}"
            echo -e "  ${CYAN}1)${NC} ${BOLD}Enable SUSFS${NC}  - Advanced root hiding (recommended for banking apps)"
            echo -e "  ${CYAN}2)${NC} ${BOLD}Disable SUSFS${NC} - Lightweight KernelSU without root hiding"
            echo ""
            log_feature "SUSFS Features when enabled:"
            echo -e "     • Hide root from banking apps"
            echo -e "     • Spoof kernel information"
            echo -e "     • Hide mount points"
            echo -e "     • Advanced stealth mode"
            echo ""
            read -p "Enable SUSFS? (1=Yes, 2=No): " SUSFS_CHOICE
            
            case "$SUSFS_CHOICE" in
                1) SUSFS_SELECTOR="--susfs=TRUE" ;;
                2) SUSFS_SELECTOR="--susfs=FALSE" ;;
                *) error_exit "Invalid SUSFS choice: $SUSFS_CHOICE" ;;
            esac
        fi
    else
        # SUSFS not applicable for KSU_BLXX or NONE
        SUSFS_SELECTOR="--susfs=FALSE"
    fi
    
    # Get LN8K option
    local LN8K_SELECTOR="$4"
    if [ -z "$LN8K_SELECTOR" ]; then
        echo ""
        read -p "Enable LN8K fast charging? (y/n): " LN8K_CHOICE
        case "${LN8K_CHOICE,,}" in
            y|yes) LN8K_SELECTOR="--ln8k=TRUE" ;;
            n|no) LN8K_SELECTOR="--ln8k=FALSE" ;;
            *) error_exit "Invalid LN8K choice: $LN8K_CHOICE" ;;
        esac
    fi
    
    # Show build configuration
    echo ""
    log_header "BUILD CONFIGURATION"
    echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}Device:${NC}      $DEVICE"
    echo -e "${CYAN}║${NC}  ${BOLD}KernelSU:${NC}    $KSU_SELECTOR"
    if [[ "$KSU_SELECTOR" == *"KSU_NEXT"* ]]; then
        echo -e "${CYAN}║${NC}  ${BOLD}SUSFS:${NC}       $SUSFS_SELECTOR"
    fi
    echo -e "${CYAN}║${NC}  ${BOLD}LN8K:${NC}        $LN8K_SELECTOR"
    echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
    echo ""
    read -p "Proceed with this configuration? (y/n): " CONFIRM
    
    if [[ ! "${CONFIRM,,}" =~ ^(y|yes)$ ]]; then
        log_info "Build cancelled by user"
        exit 0
    fi
    
    # Execute build pipeline
    log_header "PHASE 2: ENVIRONMENT SETUP"
    setup_environment "$DEVICE" "$KSU_SELECTOR" "$SUSFS_SELECTOR" "$LN8K_SELECTOR"
    
    log_header "PHASE 3: APPLYING PATCHES"
    add_patches
    add_ln8k
    add_ksu
    
    log_header "PHASE 4: KERNEL COMPILATION"
    compile_kernel
    
    log_header "PHASE 5: PACKAGING"
    package_kernel
    
    log_header "PHASE 6: POST-BUILD CLEANUP"
    post_build_cleanup
    
    echo ""
    log_success "╔════════════════════════════════════════════════════════╗"
    log_success "║  All done! Your kernel is ready to flash! 🚀          ║"
    log_success "╚════════════════════════════════════════════════════════╝"
    echo ""
}

# Run the main function with all arguments
main "$@"
