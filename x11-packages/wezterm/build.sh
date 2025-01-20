TERMUX_PKG_HOMEPAGE=https://wezfurlong.org/wezterm/
TERMUX_PKG_DESCRIPTION="A GPU-accelerated cross-platform terminal emulator and multiplexer"
TERMUX_PKG_LICENSE="MIT"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2025.01.16"
TERMUX_PKG_BUILD_DEPENDS="cmake, fakeroot, libwayland, python, xdg-utils, binutils"
TERMUX_PKG_DEPENDS="zlib, libx11, libxcb, libglvnd, mesa, xcb-util-image, xcb-util-keysyms, xcb-util-renderutil, libxkbcommon, xorgproto, freetype, fontconfig, fontconfig-utils"
TERMUX_PKG_SRCURL=git+https://github.com/wez/wezterm
_COMMIT=6c443bee9a21b6d37e06227085ddcd9633529a69
TERMUX_PKG_SHA256=ec540f328cae6b075d057bed6b1ffec9cac5df83098bf3f0d106be6f8f0e26e3
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_GIT_BRANCH=main
TERMUX_PKG_EXTRA_CONFIGURE_ARGS=("--vendored-fonts")

termux_step_post_get_source() {
	git fetch --unshallow
	git checkout $_COMMIT
	git submodule update --init --recursive

	local version="$(git log -1 --format=%cs | sed 's/-/./g')"
	if [ "$version" != "$TERMUX_PKG_VERSION" ]; then
		echo -n "ERROR: The specified version \"$TERMUX_PKG_VERSION\""
		echo " is different from what is expected to be: \"$version\""
		return 1
	fi

	local s=$(find . -type f ! -path '*/.git/*' -print0 | xargs -0 sha256sum | LC_ALL=C sort | sha256sum)
	if [[ "${s}" != "${TERMUX_PKG_SHA256}  "* ]]; then
		termux_error_exit "Checksum mismatch for source files."
	fi
}

termux_step_pre_configure() {
	termux_setup_rust
	termux_setup_cmake

	cd $TERMUX_PKG_SRCDIR
	mv ${TERMUX_PREFIX}/lib/libz.a{,.tmp} || :
	mv ${TERMUX_PREFIX}/lib/libz.so{,.tmp} || :

	: "${CARGO_HOME:=$HOME/.cargo}"
	export CARGO_HOME
	rm -rf "${CARGO_HOME}"/registry/src/*/libssh-rs-sys*
	rm -rf "${CARGO_HOME}"/registry/src/*/serial-unix*
	rm -rf "${CARGO_HOME}"/registry/src/*/termios-0.2.2*
	cargo fetch --target "${CARGO_TARGET_NAME}"

	patch -p1 -d "${CARGO_HOME}"/registry/src/*/libssh-rs-sys* \
	-i "${TERMUX_PKG_BUILDER_DIR}"/0001-disable-strerror_r.diff
	patch -p1 -d "${CARGO_HOME}"/registry/src/*/serial-unix* \
	-i "${TERMUX_PKG_BUILDER_DIR}"/0002-use-__errno.diff
}

termux_step_make() {
	LIBZ_SYS_STATIC=0
	cargo build --jobs "${TERMUX_PKG_MAKE_PROCESSES}" --target "${CARGO_TARGET_NAME}" --release
}

termux_step_make_install() {
	install -Dm700 -t "${TERMUX_PREFIX}"/bin target/"${CARGO_TARGET_NAME}"/release/wezterm
	install -Dm700 -t "${TERMUX_PREFIX}"/bin target/"${CARGO_TARGET_NAME}"/release/wezterm-gui
	install -Dm700 -t "${TERMUX_PREFIX}"/bin target/"${CARGO_TARGET_NAME}"/release/wezterm-mux-server
	install -Dm700 -t "${TERMUX_PREFIX}"/bin target/"${CARGO_TARGET_NAME}"/release/strip-ansi-escapes
}

termux_step_post_make_install() {
	mkdir -p "${TERMUX_PREFIX}"/share/bash-completion/completions
	mkdir -p "${TERMUX_PREFIX}"/share/fish/vendor_completions.d
	mkdir -p "${TERMUX_PREFIX}"/share/zsh/site-functions
	touch "${TERMUX_PREFIX}"/share/bash-completion/completions/uv
	touch "${TERMUX_PREFIX}"/share/fish/vendor_completions.d/uv.fish
	touch "${TERMUX_PREFIX}"/share/zsh/site-functions/_uv

	mv ${TERMUX_PREFIX}/lib/libz.a{.tmp,} || :
	mv ${TERMUX_PREFIX}/lib/libz.so{.tmp,} || :
}

termux_step_post_massage() {
	rm -rf $CARGO_HOME/registry/src/*/libssh-rs-sys*
	rm -rf $CARGO_HOME/registry/src/*/serial-unix*
}

termux_step_create_debscripts() {
	cat <<-EOF >./postinst
		#!${TERMUX_PREFIX}/bin/sh

		wezterm shell-completion --shell  bash > "${TERMUX_PREFIX}/share/bash-completion/completions/wezterm"
		wezterm shell-completion --shell  fish > "${TERMUX_PREFIX}/share/fish/vendor_completions.d/wezterm.fish"
		wezterm shell-completion --shell zsh > "${TERMUX_PREFIX}/share/zsh/site-functions/_wezterm"
	EOF
}
