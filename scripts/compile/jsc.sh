#!/bin/bash -e

SCRIPT_DIR=$(cd `dirname $0`; pwd)
source $SCRIPT_DIR/common.sh

CMAKE_FOLDER=$(cd $ANDROID_HOME/cmake && ls -1 | sort -r | head -1)
PATH=$TOOLCHAIN_DIR/bin:$ANDROID_HOME/cmake/$CMAKE_FOLDER/bin/:$PATH

rm -rf $TARGETDIR/webkit/$CROSS_COMPILE_PLATFORM-${FLAVOR}
rm -rf $TARGETDIR/webkit/WebKitBuild
cd $TARGETDIR/webkit/Tools/Scripts

CMAKE_CXX_FLAGS=" \
$SWITCH_JSC_CFLAGS_COMPAT \
$JSC_CFLAGS \
$PLATFORM_CFLAGS \
"

CMAKE_LD_FLAGS=" \
-latomic \
-lm \
-static-libstdc++ \
$JSC_LDFLAGS \
$PLATFORM_LDFLAGS \
"

ARCH_NAME_PLATFORM_arm="armv7-a"
ARCH_NAME_PLATFORM_arm64="aarch64"
ARCH_NAME_PLATFORM_x86="i686"
ARCH_NAME_PLATFORM_x86_64="x86_64"
var="ARCH_NAME_PLATFORM_$JSC_ARCH"
export ARCH_NAME=${!var}


if [[ "$BUILD_TYPE" = "Release" ]]
then
    BUILD_TYPE_CONFIG="--release"
    BUILD_TYPE_FLAGS=""
else
    BUILD_TYPE_CONFIG="--debug"
    BUILD_TYPE_FLAGS="-DDEBUG_FISSION=OFF"
fi

if [[ "$ARCH_NAME" = "i686" ]]
then
    JSC_FEATURE_FLAGS=" \
      -DENABLE_JIT=OFF \
      -DENABLE_C_LOOP=ON \
    "
else
    JSC_FEATURE_FLAGS=" \
      -DENABLE_JIT=ON \
      -DENABLE_C_LOOP=OFF \
    "
fi

$TARGETDIR/webkit/Tools/Scripts/build-webkit \
  --jsc-only \
  $BUILD_TYPE_CONFIG \
  --jit \
  "$SWITCH_BUILD_WEBKIT_OPTIONS_INTL" \
  --no-webassembly \
  --no-xslt \
  --no-netscape-plugin-api \
  --no-tools \
  --cmakeargs="-DCMAKE_TOOLCHAIN_FILE=${ANDROID_NDK}/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=${JNI_ARCH} \
  -DANDROID_PLATFORM=${ANDROID_API} \
  -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH \
  -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
  -DICU_ROOT=${TARGETDIR}/icu/${CROSS_COMPILE_PLATFORM}-${FLAVOR}/prebuilts \
  -DCMAKE_CXX_FLAGS='${CMAKE_CXX_FLAGS} $COMMON_CXXFLAGS $CMAKE_CXX_FLAGS' \
  -DCMAKE_C_FLAGS='${CMAKE_C_FLAGS} $CMAKE_CXX_FLAGS' \
  -DCMAKE_C_FLAGS_DEBUG='${DEBUG_SYMBOL_LEVEL}' \
  -DCMAKE_CXX_FLAGS_DEBUG='${DEBUG_SYMBOL_LEVEL}' \
  -DCMAKE_SHARED_LINKER_FLAGS='${CMAKE_SHARED_LINKER_FLAGS} $CMAKE_LD_FLAGS' \
  -DCMAKE_EXE_LINKER_FLAGS='${CMAKE_MODULE_LINKER_FLAGS} $CMAKE_LD_FLAGS' \
  -DCMAKE_VERBOSE_MAKEFILE=on \
  -DENABLE_API_TESTS=OFF \
  -DENABLE_SAMPLING_PROFILER=OFF \
  -DENABLE_DFG_JIT=ON \
  -DENABLE_FTL_JIT=OFF \
  -DUSE_SYSTEM_MALLOC=OFF \
  -DJSC_VERSION=\"${JSC_VERSION}\" \
  $JSC_FEATURE_FLAGS \
  $BUILD_TYPE_FLAGS \
  "

mkdir -p $INSTALL_UNSTRIPPED_DIR_I18N/$JNI_ARCH
mkdir -p $INSTALL_DIR_I18N/$JNI_ARCH
cp $TARGETDIR/webkit/WebKitBuild/$BUILD_TYPE/lib/libjsc.so $INSTALL_UNSTRIPPED_DIR_I18N/$JNI_ARCH
cp $TARGETDIR/webkit/WebKitBuild/$BUILD_TYPE/lib/libjsc.so $INSTALL_DIR_I18N/$JNI_ARCH
$TOOLCHAIN_DIR/bin/llvm-strip $INSTALL_DIR_I18N/$JNI_ARCH/libjsc.so
mv $TARGETDIR/webkit/WebKitBuild $TARGETDIR/webkit/${CROSS_COMPILE_PLATFORM}-${FLAVOR}
