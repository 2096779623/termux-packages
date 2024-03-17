TERMUX_PKG_HOMEPAGE=https://gofrp.org/doc
TERMUX_PKG_DESCRIPTION="A fast reverse proxy to expose a local server behind a NAT or firewall to the internet"
TERMUX_PKG_LICENSE="Apache-2.0"
TERMUX_PKG_MAINTAINER="2096779623 <admin@utermux.dev>"
TERMUX_PKG_VERSION="0.55.1"
TERMUX_PKG_SRCURL=https://github.com/fatedier/frp/archive/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=c655fdf679aa94ec9abefc625b79bfb12aecf36011e23c207e322a0748c6c693
TERMUX_PKG_REPLACES="frpc, frps"
TERMUX_PKG_BREAKS="frpc, frps"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true

termux_step_make() {
	termux_setup_golang
	if [ "$TERMUX_ARCH" = "arm" ]; then
		export GOARCH=arm
		export GOARM=7
	elif [ "$TERMUX_ARCH" = "i686" ]; then
		export GOARCH=386
		export GO386=sse2
	elif [ "$TERMUX_ARCH" = "aarch64" ]; then
		export GOARCH=arm64
	elif [ "$TERMUX_ARCH" = "x86_64" ]; then
		export GOARCH=amd64
	fi
	CGO_ENABLED=0 GOOS=android go build -trimpath -ldflags "-s -w" -tags frps -o bin/frps ./cmd/frps
	CGO_ENABLED=0 GOOS=android GOARCH=$TERMUX_ARCH go build -trimpath -ldflags "-s -w" -tags frpc -o bin/frpc ./cmd/frpc

}

termux_step_make_install() {
	install -Dm700 -t "${TERMUX_PREFIX}"/bin bin/frpc
	install -Dm700 -t "${TERMUX_PREFIX}"/bin bin/frps
}
