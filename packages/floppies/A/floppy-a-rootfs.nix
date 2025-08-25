{
  stdenv,
  busyboxi486Static,
}:
stdenv.mkDerivation {

  pname = "zplinux-floppy-a-rootfs";
  version = "1.0.0";

  phases = [ "installPhase" ];

  installPhase = ''
    runHook preInstall

    # Create a minimal root filesystem
    mkdir -p $out

    cd $out

    mkdir bin
    mkdir sbin
    mkdir dev
    mkdir proc
    mkdir sys
    mkdir tmp
    mkdir -p etc/init.d

    cp ${./floppy-a-init} sbin/init
    chmod +x sbin/init
    ln -s sbin/init init

    # Copy busybox binary and make symlinks for its applets
    cd bin
    cp -r ${busyboxi486Static}/bin/busybox busybox
    for applet in $(ls -1 ${busyboxi486Static}/bin | grep -v busybox); do
      ln -s busybox $applet
    done
    cd ..

    runHook postInstall
  '';
}
