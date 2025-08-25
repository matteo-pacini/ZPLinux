{
  pkgs,
  kerneli486,
  busyboxi486Static,
  ...
}:
let
  floppyARootFs = pkgs.callPackage ./floppy-a-rootfs.nix { inherit busyboxi486Static; };
  floppyAInitramfs = pkgs.callPackage ./floppy-a-initramfs.nix {
    inherit floppyARootFs;
  };
in
pkgs.runCommand "zplinux-floppy-a"
  {
    version = "1.0.0";
    nativeBuildInputs = [
      pkgs.mtools
      pkgs.syslinux
    ];
  }
  ''
    set -euo pipefail

    mkdir -p "$out"
    IMG="$PWD/floppy.img"

    dd if=/dev/zero of="$IMG" bs=1 count=1474560

    mformat -i "$IMG" -f 1440 ::

    # Put kernel+initrd and config under /SYSLINUX (8.3 names)
    mmd   -i "$IMG" ::/SYSLINUX
    mcopy -i "$IMG" ${kerneli486}/bzImage                 ::/SYSLINUX/BZIMAGE
    mcopy -i "$IMG" ${floppyAInitramfs}/initramfs.cpio.gz    ::/SYSLINUX/INITRD.GZ

    # Syslinux config (note: no leading slashes in paths)
    cat > syslinux.cfg <<'CFG'
    DEFAULT linux
    PROMPT 0
    TIMEOUT 20

    LABEL linux
      SAY Booting ZPLinux from RAM...
      KERNEL BZIMAGE
      APPEND initrd=INITRD.GZ devtmpfs.mount=1
    CFG
    mcopy -i "$IMG" syslinux.cfg ::/SYSLINUX/SYSLINUX.CFG
    rm -f syslinux.cfg

    syslinux --install --directory SYSLINUX "$IMG"

    # Emit final image
    cp "$IMG" "$out/zplinux-floppy-a.img"

  ''
