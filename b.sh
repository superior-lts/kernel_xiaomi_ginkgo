#!/bin/bash
#
# Compile script for Destruction kernel

SECONDS=0 # builtin bash timer
ZIPNAME="Destruction-Ginkgo-$(TZ=Asia/Jakarta date +"%Y%m%d-%H%M").zip"
TC_DIR="$(pwd)/../tc/"
CLANG_DIR="${TC_DIR}clang"
GCC_64_DIR="${TC_DIR}aarch64-linux-android-4.9"
GCC_32_DIR="${TC_DIR}arm-linux-androideabi-4.9"
DEFCONFIG="vendor/ginkgo_defconfig"
export TZ=Asia/Jakarta
export PATH="$CLANG_DIR/bin:$PATH"

# ===== TELEGRAM CONFIG =====
BOT_TOKEN="8775182477:AAGAUpRN-I-Ki2Q5AYawnIzAY1QwtRpd0J8"
CHAT_ID="-1002001516627"
API_URL="https://api.telegram.org/bot${BOT_TOKEN}"

tg_msg() {
curl -s -X POST "${API_URL}/sendMessage" \
-d chat_id="${CHAT_ID}" \
-d text="$1" \
-d parse_mode=HTML > /dev/null
}

tg_file() {
curl -s -X POST "${API_URL}/sendDocument" \
-F chat_id="${CHAT_ID}" \
-F document=@"$1" \
-F caption="$2" > /dev/null
}

# Check for essentials
if ! [ -d "${CLANG_DIR}" ]; then
echo "Clang not found! Cloning to ${CLANG_DIR}..."
if ! git clone --depth=1 https://gitlab.com/nekoprjkt/aosp-clang ${CLANG_DIR}; then
echo "Cloning failed! Aborting..."
fi
fi

if ! [ -d "${GCC_64_DIR}" ]; then
echo "gcc not found! Cloning to ${GCC_64_DIR}..."
if ! git clone --depth=1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git ${GCC_64_DIR}; then
echo "Cloning failed! Aborting..."
fi
fi

if ! [ -d "${GCC_32_DIR}" ]; then
echo "gcc_32 not found! Cloning to ${GCC_32_DIR}..."
if ! git clone --depth=1 -b lineage-19.1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git ${GCC_32_DIR}; then
echo "Cloning failed! Aborting..."
fi
fi

# ===== START NOTIF =====
tg_msg "🚀 <b>Kernel Build Started</b>
Device: <b>Redmi Note 8 (Ginkgo)</b>
Time: <code>$(date)</code>"

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) O=out ARCH=arm64 CC=clang LD=ld.lld AR=llvm-ar AS=llvm-as NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip CROSS_COMPILE=$GCC_64_DIR/bin/aarch64-linux-android- CROSS_COMPILE_ARM32=$GCC_32_DIR/bin/arm-linux-androideabi- CLANG_TRIPLE=aarch64-linux-gnu- Image.gz-dtb dtbo.img

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ] && [ -f "out/arch/arm64/boot/dtbo.img" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
fi
git clone --depth=1 -b master https://github.com/neophyteprjkt/AnyKernel3
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
cp out/arch/arm64/boot/dtbo.img AnyKernel3
rm -f *zip
cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
rm -rf AnyKernel3
rm -rf out/arch/arm64/boot

# ===== SEND ZIP =====
tg_file "$ZIPNAME" "📦 Kernel Build Finished
⏱ Time: $((SECONDS / 60))m $((SECONDS % 60))s"
