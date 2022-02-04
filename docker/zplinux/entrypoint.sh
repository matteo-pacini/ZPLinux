#/bin/bash

echo "Finalizing floppy stage..."

# Boot

echo "Mounting boot floppy..."
mount -o loop zplinux.img /mnt
echo "Copying kernel..."
cp -v /zplinux/bzImage /mnt/
echo "Copying initramfs..."
cp -v /zplinux/initramfs.cpio.gz /mnt
cat >> syslinux.cfg << 'EOF'
DEFAULT linux
LABEL linux 
  SAY Booting ZPLinux, please stand by... 
  KERNEL bzImage
  APPEND initrd=initramfs.cpio.gz
EOF
echo "Copying syslinux.cfg..."
cp -v syslinux.cfg /mnt
rm syslinux.cfg
echo "Unmounting floppy..."
umount /mnt

# Kernel modules

echo "Creating and mounting kernel modules floppy..."
dd if=/dev/zero of=zplinux_modules.img bs=512 count=2880
echo "Formatting floppy..."
mkfs.ext2 zplinux_modules.img
echo "Mounting floppy..."
mount -o loop zplinux_modules.img /mnt
echo "Copying kernel modules..."
cp -r /zplinux/modules/lib /mnt/lib
echo "Copying libc.so..."
cp /zplinux/libc.so /mnt/lib/libc.so
cat >> /mnt/install.sh << 'EOF'
#!/bin/sh
clear
echo "ZPLinux Kernel Modules & libc Floppy v.0.2"
echo "Copying kernel modules..."
rm -rf /lib
cp -r lib /
echo "Running depmod..."
depmod -a 
echo "Creating ld-musl-i386.so.1 symlinks (/lib/libc.so && /bin/ldd)..."
ln -s /lib/libc.so /lib/ld-musl-i386.so.1
ln -s /lib/ld-musl-i386.so.1 /bin/ldd
echo "Done - I bid you farewell, adventurer!"
EOF
chmod +x /mnt/install.sh
echo "Unmounting floppy..."
umount /mnt

echo "Done!"
echo "Please find the built floppy image in /floppies:"
echo

ls -lh /floppies/*.img

echo
sleep 2

/bin/sh
