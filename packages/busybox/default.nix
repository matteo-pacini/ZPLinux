{
  pkgs,
  pkgsi486,
}:
pkgsi486.pkgsStatic.busybox.overrideAttrs (old: rec {
  pname = "zplinux-busybox";
  version = "1.35.0";

  src = pkgs.fetchurl {
    url = "https://busybox.net/downloads/busybox-${version}.tar.bz2";
    hash = "sha256-+u6yRMNaNIozT0pZ5EYm7ocPsHtohNaMEK6LwZ+DppQ=";
  };

  dontAutoPatchelf = true;

  preConfigure = ''
    make allnoconfig
    cp ${./busybox-config} .config
    substituteInPlace .config \
      --replace-fail "@out@" "$out"
  '';

  configurePhase = ''
    runHook preConfigure
    make oldconfig
    runHook postConfigure
  '';

  makeFlags = [ ];
  postInstall = ''
    find $out -type f -exec i486-unknown-linux-musl-strip --strip-unneeded {} +
  '';

})
