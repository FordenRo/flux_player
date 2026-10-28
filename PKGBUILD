pkgname=flux_player
pkgver=0.1.0
pkgrel=1
pkgdesc="Flux Media Player"
arch=('x86_64')
url="https://github.com/FordenRo/flux_player"
license=("unknown")
source=("git+${url}.git")
sha256sums=('SKIP')

prepare() {
    cd "${pkgname}"
    flutter pub get
}

build() {
    cd "${pkgname}"
    flutter build linux --release
}

package() {
    cd "${pkgname}"

    install -d "${pkgdir}/opt/${pkgname}"
    cp -r "build/linux/x64/release/bundle/"* "${pkgdir}/opt/${pkgname}"
    install -d "${pkgdir}/usr/bin"
    ln -s "/opt/${pkgname}/${pkgname}" "${pkgdir}/usr/bin/${pkgname}"
    install -Dm644 "assets/logo.png" "${pkgdir}/usr/share/pixmaps/${pkgname}"
    install -d "${pkgdir}/usr/share/applications"
    cat <<EOF > "${pkgdir}/usr/share/applications/${pkgname}.desktop"
[Desktop Entry]
Version=0.1.0
Type=Application
Name=Flux Player
Comment=${pkgdesc}
Exec=${pkgname}
Icon=${pkgname}
Terminal=false
StartupWMClass=flux_player
Categories=AudioVideo;Audio;
EOF
}
