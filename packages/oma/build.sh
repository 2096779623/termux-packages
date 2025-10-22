TERMUX_PKG_HOMEPAGE=https://aosc.io/oma
TERMUX_PKG_DESCRIPTION="oma is an attempt at reworking APT's interface"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="1.22.3"
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL="https://github.com/AOSC-Dev/oma/archive/refs/tags/v${TERMUX_PKG_VERSION}.tar.gz"
TERMUX_PKG_SHA256=55dbf68a329e3c4f9422b9b5ed0714071392f9f9e11aa17bdd84c0ac10339118
TERMUX_PKG_DEPENDS="libnettle, apt"
TERMUX_PKG_RECOMMENDS="ripgrep"
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
--no-default-features
--features nice-setup
"

termux_step_pre_configure() {
	termux_setup_rust

	# error: function-like macro '__GLIBC_USE' is not defined
	export BINDGEN_EXTRA_CLANG_ARGS_${CARGO_TARGET_NAME//-/_}="--sysroot ${TERMUX_STANDALONE_TOOLCHAIN}/sysroot --target=${CARGO_TARGET_NAME}"
	CXXFLAGS+=" $CPPFLAGS"
}

termux_step_make() {
	cargo build --jobs $TERMUX_PKG_MAKE_PROCESSES --target $CARGO_TARGET_NAME --release
}

termux_step_make_install() {
	mkdir -p $TERMUX_PREFIX/share/man/man1
	mkdir -p $TERMUX_PREFIX/etc/apt/apt.conf.d

	install -Dm700 -t $TERMUX_PREFIX/bin target/${CARGO_TARGET_NAME}/release/oma
	install -m644 "${TERMUX_PKG_SRCDIR}/data/config/oma-debian.toml" "${TERMUX_PREFIX}/etc/oma.toml"
	install -m644 "${TERMUX_PKG_SRCDIR}/data/apt.conf.d/50oma-debian.conf" "${TERMUX_PREFIX}/etc/apt/apt.conf.d/50oma.conf"
}

termux_step_post_make_install() {
	install -Dm644 /dev/null "$TERMUX_PREFIX"/share/bash-completion/completions/oma
	install -Dm644 /dev/null "$TERMUX_PREFIX"/share/zsh/site-functions/_oma
	install -Dm644 /dev/null "$TERMUX_PREFIX"/share/fish/vendor_completions.d/oma.fish
}

termux_step_create_debscripts() {
	cat <<-EOF >./postinst
		#!${TERMUX_PREFIX}/bin/sh
		COMPLETE=bash oma > ${TERMUX_PREFIX}/share/bash-completion/completions/oma
		COMPLETE=zsh oma > ${TERMUX_PREFIX}/share/zsh/site-functions/_oma
		COMPLETE=fish oma > ${TERMUX_PREFIX}/share/fish/vendor_completions.d/oma.fish
		oma generate-manpages -p $TERMUX_PREFIX/tmp/
		mv $TERMUX_PREFIX/tmp/man/*/*.1 $TERMUX_PREFIX/share/man/man1/
	EOF
}
