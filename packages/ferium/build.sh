TERMUX_PKG_HOMEPAGE=https://github.com/gorilla-devs/ferium
TERMUX_PKG_DESCRIPTION="Fast and multi-source CLI program for managing Minecraft mods and modpacks"
TERMUX_PKG_LICENSE="MPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="4.5.2"
TERMUX_PKG_SRCURL=https://github.com/gorilla-devs/ferium/archive/refs/tags/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=5b4fde3eee2336c4874d8bf5c412e019843f9cef018f750bbb4c51c1fceb9484
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true

termux_step_pre_configure() {
	termux_setup_rust
}

termux_step_make() {
	cargo build --jobs $TERMUX_MAKE_PROCESSES --target $CARGO_TARGET_NAME --release
}

termux_step_make_install() {
	install -Dm700 -t $TERMUX_PREFIX/bin target/${CARGO_TARGET_NAME}/release/ferium
}
