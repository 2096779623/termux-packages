TERMUX_PKG_HOMEPAGE=https://github.com/pystardust/ani-cli
TERMUX_PKG_DESCRIPTION="A cli to browse and watch anime"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="4.10"
TERMUX_PKG_SRCURL=https://github.com/pystardust/ani-cli/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=bf9a61baa70cbbe9028084982b2661c7a0d69823d82534b818abf49e2139d120
TERMUX_PKG_DEPENDS="aria2, ffmpeg, fzf, grep, sed, wget"
TERMUX_PKG_ANTI_BUILD_DEPENDS="aria2, ffmpeg, fzf, grep, sed, wget"
TERMUX_PKG_PLATFORM_INDEPENDENT=true
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true

termux_step_make_install() {
	install -Dm700 -t $TERMUX_PREFIX/bin ani-cli

	local mpv_android=$TERMUX_PREFIX/opt/ani-cli/bin/mpv
	mkdir -p $(dirname $mpv_android)
	rm -rf $mpv_android
	sed 's|@TERMUX_PREFIX@|'"$TERMUX_PREFIX"'|g' \
		$TERMUX_PKG_BUILDER_DIR/mpv.in > $mpv_android
	chmod 0700 $mpv_android
}

termux_step_create_debscripts() {
	cat <<- EOF > ./postinst
	#!${TERMUX_PREFIX}/bin/sh
	echo
	echo Note that you need to have the mpv android app installed.
	echo
	EOF
}
