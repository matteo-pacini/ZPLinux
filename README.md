# ZPLinux

<img src="./images/cmatrix.gif" width="500" height="300" />
    
A tailored Linux release for my 486 FreeDOS machine.

(Yeah, that's [cmatrix](https://github.com/abishekvashok/cmatrix) burning the CPU)

Comes in two lovely floppy diskettes.

<img src="./images/diskettes.jpg" width="375" height="280" />

---

## Target Machine

- **Motherboard**: Jetway-437 (VESA, PCI)
- **CPU**: Intel 486 DX2 - 66Mhz
- **RAM**: 4x4MB EDO RAM (16MB)
- **VGA**: S3 Virge/DX 4MB
- **Sound**: Creative SB16 Vibra PnP (ISA)
- **Network**: RTL8029AS
- **HDD**: Samsung WN312021A (1,2GB)
- **CD-ROM**: LG GCR-8520b
- **Floppy**: 3.5” 1.44MB
- **Keyboard**: DYN5 UK Keyboard
- **Mouse**: Microsoft Serial Mouse (2 buttons)

<img src="./images/chassis.jpg" width="150" height="200" />

---

## Screenshots 

Boot time from when the floppy is triggered to usable shell (around 1m27s).
<img src="./images/boottime.jpg" width="500" height="330" />

---

## More Screenshots (QEMU)

<img src="./images/qemu_intro.png" width="500" height="330" />

<img src="./images/qemu_mem.png" width="500" height="330" />

<img src="./images/qemu_modules.png" width="500" height="330" />

---

## Problems & Solutions

- I want a modern kernel built with a modern toolchain
    - SOLUTION: **Build a bespoke i486 toolchain, and build the kernel with it**
- Glibc creates massive binaries and binary size is a top concern here
    - SOLUTION: **use musl instead of glibc**
- Cross-compiling on macOS is painful:
    - Filesystem issues (e.g. filesystem not being case-sensitive by default)
    - GNU tools don't always behave correctly
    - M1 is based on ARM - a few tools may not run at all (e.g. syslinux)
    - I don't want to pollute the filesystem of my Macbook.
    - SOLUTION: **Use Docker**

---

## Kernel Configuration

Modules are a must - it's impossibile to fit everything into a floppy. The non-essential modules will be offloaded to the second floppy.

    - Enable loadable module support
    - Enable block layer
    - General setup -> swap 
    - General setup -> initramfs/initrd support (gzip only)

Some generic must-have features  

    - General setup -> Kernel Features (expert) -> printk
    - General setup -> Kernel Features (expert) -> PC-Speaker
    - Executable file formats -> ELF binaries
    - Executable file formats -> Scripts starting with #!
    - Device drivers -> Generic driver options -> devtmpfs

Processor configuration

<img src="./images/cpu.jpg" width="150" height="200" />

    - Processor -> Family -> 486DX
    - Processor -> Load address -> 0x400000

The motherboard supports both ISA and PCI, so...

<img src="./images/mobo.jpg" width="150" height="200" />


    - Bus -> ISA support
    - Device drivers -> PCI support

For the block devices, the machine uses SCSI/PATA.

<img src="./images/hdd.jpg" width="150" height="200" />
<img src="./images/cdrom.jpg" width="150" height="200" />

    - Device drivers -> Block devices -> Normal floppy support
    - Device drivers -> SCSI -> SCSI device support
    - Device drivers -> SCSI -> SCSI disk support
    - Device drivers -> SCSI -> SCSI CDROM
    - Device drivers -> SATA/PATA -> ATA SFF support
    - Device drivers -> SATA/PATA -> Generic platform device PATA support
    - Device drivers -> SATA/PATA -> Legacy ISA PATA support

For the VGA

<img src="./images/vga.jpg" width="300" height="200" />


    - Device drivers -> Graphics -> Framebuffer support -> S3 Trio/Virge 

Filesystems (ext2, fat, vfat and ISO9660)

    - File systems -> EXT2                  
    - File systems -> CDROM -> ISO9660                  
    - File systems -> DOS/VFAT/etc -> MSDOS                  
    - File systems -> DOS/VFAT/etc -> VFAT                  
    - File systems -> Pseudo -> /proc                  
    - File systems -> Pseudo -> sysfs                  
    - File systems -> NLS -> Codepage 437                  
    - File systems -> NLS -> ISO 8859-1  

Mouse (module) and keyboard

    - Device drivers -> Input device support -> Keyboards -> AT
    - Device drivers -> Input device support -> Mice -> Serial 

Sound card (ISA PnP)

<img src="./images/sb16.jpg" width="300" height="200" />

    - Device drivers -> PNP support -> ISA PNP   
    - Device drivers -> Sound card support -> ISA devices -> SB16 PnP    

Parallel port (module)

    - Device drivers -> Parallel port support -> PC-Style hardware  

PC speaker (module)

    - Device drivers -> Input device support -> Miscellaneous -> PC Speaker  

 TTY

    - Device drivers -> Character devices -> TTY
    - Device drivers -> Character devices -> TTY / Output messages to printk

---

## Busybox settings

TBW

---

## Docker images

### Provided files

- `busybox-config` and `kernel-config` are self-explanatory.
- `busybox-init` is the main initramfs script.
- `entrypoint.sh` is the entrypoint script for the `zplinux` image that builds kernel and busybox, and also creates the floppies.
- `floppy.img` is a dump of a physical floppy diskette, formatted under FreeDOS 1.3RC5 and with Syslinux 4.x installed on it

### 486toolchain

This image builds a `i486-linux-musl-*` prefixed cross-compiler toolchain in `/toolchain`.

It is the base image for the `zplinux` one.

It also includes ncurses and zlib.

### zplinux

This image compiles and packages the kernel and busybox at build time.

The floppy disk(s) are created at runtime by the entrypoint script.

---

## Running

    # Build toolchain image
    docker build -t 486toolchain ./486toolchain 
    # Build zplinux image
     docker build -t zplinux ./zplinux
    # Finalise zplinux build (privileged is required to mount the floppies)
    docker run --rm -ti -v /some/output/folder:/data --privileged zplinux

    # Once the floppy is built, copy it to /data
    docker-machine> cp /floppies/*.img /data
    docker-machine> exit

    # Flash it (or test it in QEMU - see below)
    sudo dd if=/path/to/zplinux.img of=DEVICE bs=512 count=2880 conv=noerror,sync

## QEMU

    qemu-system-i386 -cpu 486 -m 16 -fda zplinux.img

## Must Read

Articles that inspired my Linux quest:

- [Floppinux - An Embedded 🐧Linux on a Single 💾Floppy](https://bits.p1x.in/floppinux-an-embedded-linux-on-a-single-floppy/) by Krzysztof Krystian Jankowski
- [Linux on a 486SX](https://ocawesome101.github.io/486-linux.html) by Ocawesome101

