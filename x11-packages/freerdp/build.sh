TERMUX_PKG_HOMEPAGE=https://www.freerdp.com/
TERMUX_PKG_DESCRIPTION="A free remote desktop protocol library and clients"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="3.6.2"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_SRCURL=https://github.com/FreeRDP/FreeRDP/archive/refs/tags/$TERMUX_PKG_VERSION.tar.gz
TERMUX_PKG_SHA256=e16260946a1d3289339bf158f335d9dddd9af43b96050b6b6fba287310df9924
TERMUX_PKG_DEPENDS="libandroid-shmem, libcairo, libjpeg-turbo, libusb, libwayland, libx11, libxcursor, libxdamage, libxext, libxfixes, libxi, libxinerama, libxkbcommon, libxkbfile, libxrandr, libxrender, libxv, openssl, pulseaudio, zlib, libicu, sdl2"
TERMUX_PKG_BUILD_DEPENDS="libwayland-cross-scanner, libwayland-protocols"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DANDROID_NO_TERMUX=OFF
-DWITH_LIBSYSTEMD=OFF
-DWITH_PULSE=ON
-DWITH_OPENSLES=OFF
-DWITH_OSS=OFF
-DWITH_ALSA=OFF
-DWITH_CUPS=OFF
-DWITH_PCSC=OFF
-DWITH_FFMPEG=OFF
-DWITH_JPEG=ON
-DWITH_OPENSSL=ON
-DWITH_SERVER=ON
-DWITH_KRB5=OFF
-DWITH_SWSCALE=OFF
-DWITH_FUSE=OFF
"

termux_pkg_auto_update() {
	local latest_tag="$(termux_github_api_get_tag "${TERMUX_PKG_SRCURL}" latest-regex 3)"
	[[ -z "${latest_tag}" ]] && termux_error_exit "ERROR: Unable to get tag from ${TERMUX_PKG_SRCURL}"
	termux_pkg_upgrade_version "${latest_tag}"
}

termux_step_post_get_source() {
	find "$TERMUX_PKG_SRCDIR" -name CMakeLists.txt -o -name '*.cmake' | \
		xargs -n 1 sed -i \
		-e 's/\([^A-Za-z0-9_]ANDROID\)\([^A-Za-z0-9_]\)/\1_NO_TERMUX\2/g' \
		-e 's/\([^A-Za-z0-9_]ANDROID\)$/\1_NO_TERMUX/g'
}

termux_step_pre_configure() {
	export PATH="$TERMUX_PREFIX/opt/libwayland/cross/bin:$PATH"

	CPPFLAGS+=" -D__USE_BSD"
	LDFLAGS+=" -landroid-shmem"
}
