{
  pkgsi486,
  stdenv,
  lib,
  fetchurl,
  flex,
  bison,
  bc,
  ncurses,
  pkg-config,

  forMenuConfig ? false,
}:
stdenv.mkDerivation rec {
  pname = "zplinux-kernel";
  version = "5.15.189";

  src = fetchurl {
    url = "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-${version}.tar.xz";
    hash = "sha256-49ACW4cnjhRzPLMmcA8Xx8zrVNkgYisNX81YqIxoUMM=";
  };

  dontAutoPatchelf = true;

  nativeBuildInputs = [
    # Unwrapped bintools and compiler
    pkgsi486.stdenv.cc.bintools.bintools
    pkgsi486.stdenv.cc.cc
    flex
    bison
    bc
  ]
  ++ lib.optionals forMenuConfig [
    ncurses
    pkg-config
  ];

  env = {
    ARCH = "x86";
    CROSS_COMPILE = "i486-unknown-linux-musl-";
  };

  buildPhase = ''
    runHook preBuild
    cp ${./kernel-config} .config
    make -j''${NIX_BUILD_CORES} KCFLAGS="-Os -g0 -march=i486 -mcpu=i486 -mtune=i486"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp arch/x86/boot/bzImage $out/ 
    make INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=$out modules_install
    runHook postInstall
  '';

}
