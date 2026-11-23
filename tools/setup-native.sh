#!/bin/sh
# Installs what deui's native windows need besides SDL3: wgpu-native, at
# the version ThorVG is built against, and ThorVG with its WebGPU engine,
# TrueType loader and C API. Both go under $PREFIX (default /usr/local),
# which is added to the dynamic linker's path.
#
# Needs curl, unzip, git, meson, ninja and a C++ compiler; and, to run the
# windows, SDL3 and a Vulkan driver. On Arch:
#   pacman -S sdl3 curl unzip git meson ninja gcc vulkan-icd-loader
# plus the Vulkan driver for the GPU (vulkan-radeon, vulkan-intel, or
# nvidia-utils).
set -eu

PREFIX=${PREFIX:-/usr/local}
WGPU=v29.0.1.1
THORVG=v1.1.4
SUDO=${SUDO-$( [ "$(id -u)" = 0 ] || echo sudo )}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"

echo "wgpu-native $WGPU"
curl -fsSL -o wgpu.zip \
  "https://github.com/gfx-rs/wgpu-native/releases/download/$WGPU/wgpu-linux-$(uname -m)-release.zip"
unzip -q wgpu.zip -d wgpu
$SUDO install -Dm644 wgpu/lib/libwgpu_native.so "$PREFIX/lib/libwgpu_native.so"
$SUDO install -Dm644 wgpu/include/webgpu/webgpu.h "$PREFIX/include/webgpu/webgpu.h"
$SUDO install -Dm644 wgpu/include/webgpu/wgpu.h "$PREFIX/include/webgpu/wgpu.h"
cat > wgpu_native.pc <<PC
prefix=$PREFIX
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: wgpu_native
Description: WebGPU's C API, on Vulkan, Metal or DirectX
Version: ${WGPU#v}
Libs: -L\${libdir} -lwgpu_native
Cflags: -I\${includedir}
PC
$SUDO install -Dm644 wgpu_native.pc "$PREFIX/lib/pkgconfig/wgpu_native.pc"

echo "ThorVG $THORVG"
git -c advice.detachedHead=false clone -q --depth 1 --branch "$THORVG" https://github.com/thorvg/thorvg
PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig" meson setup thorvg/build thorvg \
  --buildtype=release --prefix="$PREFIX" --libdir=lib \
  -Dengines=cpu,wg -Dloaders=ttf -Dbindings=capi >/dev/null
ninja -C thorvg/build >/dev/null
$SUDO ninja -C thorvg/build install >/dev/null

echo "$PREFIX/lib" | $SUDO tee /etc/ld.so.conf.d/deui.conf >/dev/null
$SUDO ldconfig
echo "done: $PREFIX/lib/libwgpu_native.so, $PREFIX/lib/libthorvg-1.so.1"
