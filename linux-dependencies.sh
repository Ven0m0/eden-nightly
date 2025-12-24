#!/bin/sh -e
# shellcheck enable=all shell=sh source-path=SCRIPTDIR
LC_ALL=C

ARCH="$(uname -m)"
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	base-devel \
	catch2 \
	clang \
	cmake \
	gamemode \
	git \
	glslang \
 	inetutils \
 	jq \
	libva libvdpau libvpx \
 	lld llvm llvm-libs \
	nasm \
	ninja \
	numactl \
 	mold \
	p7zip \
	patchelf \
	pulseaudio pulseaudio-alsa \
	python-pip \
	qt6ct qt6-tools \
 	sdl3 \
	strace \
	unzip \
	vulkan-headers vulkan-mesa-layers \
	wget \
 	wireless_tools \
  	xcb-util-cursor xcb-util-image xcb-util-renderutil \
	xcb-util-wm xorg-server-xvfb \
	zip zsync

if [ "$(uname -m)" = 'x86_64' ]; then
  pacman -Syu --noconfirm --overwrite "*" haskell-gnutls svt-av1
fi
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh && chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh --add-mesa qt6-base-mini libxml2-mini llvm-libs-mini opus-nano intel-media-driver

echo "All done!"
echo "---------------------------------------------------------------"
