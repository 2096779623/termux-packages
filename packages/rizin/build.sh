TERMUX_PKG_HOMEPAGE=https://rizin.re
TERMUX_PKG_DESCRIPTION="UNIX-like reverse engineering framework and command-line toolset."
TERMUX_PKG_LICENSE="GPL-3.0, LGPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="0.8.1"
# Use source tarball from release assets to get all bundled projects
TERMUX_PKG_SRCURL=https://github.com/rizinorg/rizin/releases/download/v${TERMUX_PKG_VERSION}/rizin-src-v${TERMUX_PKG_VERSION}.tar.xz
TERMUX_PKG_DEPENDS="capstone, file, libandroid-execinfo, liblz4, liblzma, libzip, openssl, tree-sitter, xxhash, zlib, zstd"
TERMUX_PKG_SUGGESTS="python, apk-tools, apktool, apksigner"
TERMUX_PKG_SHA256=ef2b1e6525d7dc36ac43525b956749c1cca07bf17c1fed8b66402d82010a4ec2
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-Denable_tests=false
-Denable_rz_test=false
-Duse_capstone_version=v5
-Duse_lzma=true
-Duse_sys_capstone=enabled
-Duse_sys_libzip=enabled
-Duse_sys_libzip_openssl=true
-Duse_sys_libzstd=enabled
-Duse_sys_lz4=enabled
-Duse_sys_lzma=enabled
-Duse_sys_magic=enabled
-Duse_sys_openssl=enabled
-Duse_sys_tree_sitter=enabled
-Duse_sys_xxhash=enabled
-Duse_sys_zlib=enabled
-Duse_zlib=true
"

termux_step_pre_configure() {
	# for backtrace and backtrace_symbols_fd
	LDFLAGS+=" -landroid-execinfo"
}
