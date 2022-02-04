# syntax=docker/dockerfile:1

###############
# BUILD STAGE #
###############

FROM 486toolchain:latest as build

RUN apk add --update --no-cache --virtual .build-deps build-base curl gawk flex bison git bc cpio xz ncurses-dev linux-headers perl texinfo

WORKDIR /src

##########
# KERNEL #
##########

# Prepare kernel
RUN git clone --depth=1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git && \
    cd linux && \
    make distclean

# Copy config
COPY kernel-config linux/.config

# Build kernel and modules, copy everything to /zplinux, and then clean up
RUN mkdir -p /zplinux/modules && \
    cd linux && \
    make -j$(nproc --all) KCFLAGS="-Os -g0 -march=i486 -mcpu=i486 -mtune=i486" && \
    cp arch/x86/boot/bzImage /zplinux && \
    make INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=/zplinux/modules modules_install

###########
# BUSYBOX #
###########

# Fetch and bootstrap busybox
RUN curl https://busybox.net/downloads/busybox-1.35.0.tar.bz2 -o busybox-1.35.0.tar.bz2 && \
    tar xjf busybox-1.35.0.tar.bz2 && \
    cd busybox-1.35.0 && \
    make distclean

COPY busybox-config busybox-1.35.0/.config

RUN cd busybox-1.35.0 && \
    make -j$(nproc --all) && \
    make install && \
    cd _install && \
    mkdir dev && \
    mkdir proc && \
    mkdir -p etc/init.d && \
    mkdir sys && \
    mkdir tmp && \
    mkdir -p usr/share/terminfo/l && \
    cp /toolchain/i486-linux-musl/usr/share/terminfo/l/linux usr/share/terminfo/l/ && \
    mknod dev/console c 5 1 && \
    mknod dev/null c 1 3

COPY busybox-init busybox-1.35.0/_install/sbin/init

RUN cd busybox-1.35.0/_install && \
    chmod +x sbin/init && \
    ln -s sbin/init init && \
    chown -R root:root . && \
    find . | cpio -H newc -o | gzip -9 > /zplinux/initramfs.cpio.gz

RUN cp /toolchain/i486-linux-musl/lib/libc.so /zplinux/

##################
# FLOPPIES STAGE #
##################

FROM alpine:latest as floppies

RUN apk add --update e2fsprogs

COPY --from=build /zplinux /zplinux

WORKDIR /floppies

COPY floppy.img zplinux.img
COPY entrypoint.sh entrypoint.sh

ENTRYPOINT /floppies/entrypoint.sh
