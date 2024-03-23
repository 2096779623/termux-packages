TERMUX_PKG_HOMEPAGE=https://github.com/cloudflare/cloudflared
TERMUX_PKG_DESCRIPTION="A tunneling daemon that proxies traffic from the Cloudflare network to your origins"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="@termux"
TERMUX_PKG_VERSION="2024.3.0"
TERMUX_PKG_SRCURL=https://github.com/cloudflare/cloudflared/archive/refs/tags/${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=6e5fda072d81b2d40208a0d244b44aaf607f26709711e157e23f44f812594e93
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_post_get_source() {
	git clone https://github.com/cloudflare/go
	cd go/src
	./make.bash
}

termux_step_make() {
	cd $TERMUX_PKG_SRCDIR
	ls -lah
	local _DATE=$(date -u '+%Y.%m.%d-%H:%M UTC')
	./go/bin/go build -v -ldflags "-X \"main.Version=$TERMUX_PKG_VERSION\" -X \"main.BuildTime=$_DATE\"" \
		./cmd/cloudflared
}

termux_step_make_install() {
	install -Dm700 -t $TERMUX_PREFIX/bin cloudflared
}
