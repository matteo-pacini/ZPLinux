{
  runCommand,
  cpio,
  gzip,
  floppyARootFs,
}:
runCommand "zplinux-floppy-a-initramfs"
  {
    version = "1.0.0";
    nativeBuildInputs = [
      cpio
      gzip
    ];
  }
  ''
    mkdir -p $out
    cd ${floppyARootFs}
    find . -print0 | cpio --null -H newc -o | gzip -9 > "$out/initramfs.cpio.gz"
  ''
