# syntax=docker/dockerfile:1

FROM alpine:latest

RUN apk add --update --no-cache --virtual .build-deps build-base pkgconfig && \
    apk add --update --no-cache --virtual .situational-build-deps curl gawk flex bison file git rsync perl texinfo

WORKDIR /src

# Download source tarballs and extract them
RUN curl https://ftp.gnu.org/gnu/binutils/binutils-2.37.tar.bz2 -o binutils-2.37.tar.bz2 && tar xjf binutils-2.37.tar.bz2 && \
    curl https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz -o gcc-11.2.0.tar.xz && tar xf gcc-11.2.0.tar.xz && \
    curl https://musl.libc.org/releases/musl-1.2.2.tar.gz -o musl-1.2.2.tar.gz && tar xzf musl-1.2.2.tar.gz && \
    cd gcc-11.2.0 && contrib/download_prerequisites

# Fetch latest stable kernel and install headers
RUN git clone --depth=1 https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git && \
    cd linux && \
    make ARCH=x86 INSTALL_HDR_PATH=/toolchain/i486-linux-musl/usr headers_install && \
    cd .. && \
    rm -rf linux

# Configure,build and install binutils, then clean up
RUN mkdir build-binutils && \
    cd build-binutils && \
    ../binutils-2.37/configure --prefix=/toolchain \
    --build=$MACHTYPE \
    --host=$MACHTYPE \
    --target=i486-linux-musl \
    --disable-multilib \
    --disable-nls \
    --disable-werror \
    --disable-threads \
    --with-sysroot=/toolchain/i486-linux-musl \
    CFLAGS="-O2 -g0" \
    CXXFLAGS="-g0 -O2" && \
    make -j$(nproc --all) && \
    make install && \
    cd .. && \
    rm -rf binutils-2.37 build-binutils binutils-2.37.tar.bz2

ENV PATH="$PATH:/toolchain/bin"

# Configure & build a minimal GCC so we can build musl
RUN mkdir build-gcc && \
    cd build-gcc && \
    ../gcc-11.2.0/configure --prefix= \
    --with-sysroot=/toolchain/i486-linux-musl \
    --build=$MACHTYPE \
    --host=$MACHTYPE \
    --target=i486-linux-musl \
    --disable-multilib \
    --disable-nls \
    --enable-languages=c \
    --disable-werror \
    --disable-threads \
    --disable-libgomp \
    --disable-libsanitizer \
    --with-newlib \
    --without-headers \
    --disable-shared \
    --with-arch=i486 \
    --with-cpu=i486 \
    --with-tune=i486 \
    CFLAGS="-O2 -g0" \
    CXXFLAGS="-g0 -O2" && \
    make -j$(nproc --all) all-gcc all-target-libgcc

# Configure, build and install i486 optimized musl, then clean up
RUN cd musl-1.2.2 && \
    CC="../build-gcc/gcc/xgcc -B ../build-gcc/gcc" \
    LIBCC="../build-gcc/i486-linux-musl/libgcc/libgcc.a" \
    CFLAGS="-Os -g0 -march=i486 -mcpu=i486 -mtune=i486"  \
    CXXFLAGS="-g0 -Os -march=i486 -mcpu=i486 -mtune=i486" \
    ./configure --prefix= --host=i486-linux-musl && \
    make -j$(nproc --all) && \
    make DESTDIR=/toolchain/i486-linux-musl install && \
    cd .. && \
    rm -rf musl-1.2.2 musl-1.2.2.tar.gz

# Build the final GCC and install it
RUN cd build-gcc && \
    rm -rf * && \
    ../gcc-11.2.0/configure --prefix=/toolchain \
    --with-sysroot=/toolchain/i486-linux-musl \
    --build=$MACHTYPE \
    --host=$MACHTYPE \
    --target=i486-linux-musl \
    --disable-multilib \
    --disable-nls \
    --enable-languages=c,c++ \
    --disable-werror \
    --disable-threads \
    --disable-libgomp \
    --disable-libsanitizer \
    --with-arch=i486 \
    --with-cpu=i486 \
    --with-tune=i486 \
    --enable-checking=release \
    CFLAGS="-O2 -g0" \
    CXXFLAGS="-g0 -O2" && \
    make -j$(nproc --all) && \
    make install && \
    cd .. && \
    rm -rf gcc-11.2.0 build-gcc gcc-11.2.0.tar.xz

# Toolchain test
RUN echo "int main() { return 0; }" | i486-linux-musl-gcc -x c --static -o /dev/null - && \
    echo "int main() { return 0; }" | i486-linux-musl-gcc -x c -o /dev/null - && \
    echo "int main() { return 0; }" | i486-linux-musl-g++ -x c++ --static -o /dev/null - && \
    echo "int main() { return 0; }" | i486-linux-musl-g++ -x c++ -o /dev/null -  && \
    echo "int main() { return 0; }" | i486-linux-musl-gcc -x c -o /tmp/c.test - && \
    file /tmp/c.test | grep -q "ELF 32-bit LSB executable" && \
    file /tmp/c.test | grep -q "80386"

# Create a pkg-config wrapper for the toolchain
# https://autotools.info/pkgconfig/cross-compiling.html
RUN echo "#!/bin/sh" > /toolchain/bin/i486-linux-musl-pkg-config && \
    echo 'SYSROOT=/toolchain/i486-linux-musl' >> /toolchain/bin/i486-linux-musl-pkg-config && \
    echo 'export PKG_CONFIG_PATH=' >> /toolchain/bin/i486-linux-musl-pkg-config && \
    echo 'export PKG_CONFIG_LIBDIR=${SYSROOT}/usr/lib/pkgconfig:${SYSROOT}/usr/share/pkgconfig' >> /toolchain/bin/i486-linux-musl-pkg-config && \
    echo 'export PKG_CONFIG_SYSROOT_DIR=${SYSROOT}' >> /toolchain/bin/i486-linux-musl-pkg-config && \
    echo 'exec pkg-config "$@"' >> /toolchain/bin/i486-linux-musl-pkg-config && \
    chmod +x /toolchain/bin/i486-linux-musl-pkg-config

# Download, extract, configure, build and install ncurses
# https://www.linuxfromscratch.org/lfs/view/development/chapter06/ncurses.html
# Note I: --enable-pc-files explodes without setting PKG_CONFIG_LIBDIR!
RUN curl https://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.3.tar.gz -o ncurses-6.3.tar.gz && \
    tar xzf ncurses-6.3.tar.gz && \
    cd ncurses-6.3 && \
    mkdir build && cd build && \
    ../configure && make -j$(nproc --all) -C include && make -j$(nproc --all) -C progs tic && cd .. && \
    ./configure --prefix=/usr --host=i486-linux-musl --build=$MACHTYPE \
    --with-manpage-format=normal \
    --mandir=/usr/share/man \
    --with-shared \
    --without-debug \
    --without-ada \
    --disable-stripping \
    --enable-widec \
    --enable-pc-files \
    PKG_CONFIG_LIBDIR="/usr/lib/pkgconfig" \
    CFLAGS="-Os -g0 -march=i486 -mcpu=i486 -mtune=i486"  \
    CXXFLAGS="-g0 -Os -march=i486 -mcpu=i486 -mtune=i486" && \
    make -j$(nproc --all) && \
    make DESTDIR=/toolchain/i486-linux-musl TIC_PATH=$(pwd)/build/progs/tic install && \
    cd .. && rm -rf ncurses-6.3.tar.gz ncurses-6.3 && \
    echo "INPUT(-lncursesw)" > /toolchain/i486-linux-musl/usr/lib/libncurses.so && \
    echo "INPUT(-l:libncursesw.a)" > /toolchain/i486-linux-musl/usr/lib/libncurses.a

# Download, extract, configure, build and install zlib
RUN curl https://zlib.net/zlib-1.2.11.tar.xz -o zlib-1.2.11.tar.xz && \
    tar xf zlib-1.2.11.tar.xz && \
    cd zlib-1.2.11 && \
    CC="i486-linux-musl-gcc" \
    AR="i486-linux-musl-ar" \
    RANLIB="i486-linux-musl-ranlib" \
    CFLAGS="-Os -g0 -march=i486 -mcpu=i486 -mtune=i486"  \
    CXXFLAGS="-g0 -Os -march=i486 -mcpu=i486 -mtune=i486" \
    ./configure --prefix=/usr && \
    make -j$(nproc --all) && \
    make DESTDIR=/toolchain/i486-linux-musl install && \
    cd .. && rm -rf zlib-1.2.11.tar.xz zlib-1.2.11

RUN apk add --update --no-cache --virtual .libxml2-deps wget && \
    wget ftp://xmlsoft.org/libxml2/libxml2-2.9.11.tar.gz && \
    tar xzf libxml2-2.9.11.tar.gz && \
    cd libxml2-2.9.11 && \
    ./configure --prefix=/usr --host=i486-linux-musl --without-threads \
        CFLAGS="-Os -g0 -march=i486 -mcpu=i486 -mtune=i486"  \
        CXXFLAGS="-g0 -Os -march=i486 -mcpu=i486 -mtune=i486" && \
    make -j$(nproc --all) && \
    make DESTDIR=/toolchain/i486-linux-musl install && \
    cd .. && rm -rf libxml2-2.9.11.tar.gz libxml2-2.9.11 && \
    apk del .libxml2-deps

# Download, extract, configure, build and install gettext
RUN curl https://ftp.gnu.org/pub/gnu/gettext/gettext-0.21.tar.gz -o gettext-0.21.tar.gz && \
    tar xzf gettext-0.21.tar.gz && \
    cd gettext-0.21 && \
    ./configure --prefix=/usr --host=i486-linux-musl \
        --disable-threads \
        CFLAGS="-Os -g0 -march=i486 -mcpu=i486 -mtune=i486" \
        CXXFLAGS="-g0 -Os -march=i486 -mcpu=i486 -mtune=i486" && \
    make -j$(nproc --all) && \
    make DESTDIR=/toolchain/i486-linux-musl install && \
    cd .. && rm -rf gettext-0.21.tar.gz gettext-0.21

# Download, extract, configure, build and install gzip
RUN curl -L https://ftp.gnu.org/gnu/gzip/gzip-1.11.tar.xz -o gzip-1.11.tar.xz && \
    tar xf gzip-1.11.tar.xz && \
    cd gzip-1.11 && \
    ./configure --prefix=/usr --host=i486-linux-musl \
        --disable-threads \
        CFLAGS="-Os -g0 -march=i486 -mcpu=i486 -mtune=i486"  \
        CXXFLAGS="-g0 -Os -march=i486 -mcpu=i486 -mtune=i486" && \
    make -j$(nproc --all) && \
    make DESTDIR=/toolchain/i486-linux-musl install && \
    cd .. && rm -rf gzip-1.11.tar.xz gzip-1.11

# Download, extract, configure, build and install bzip2
# https://clfs.org/view/clfs-sysroot/x86/final-system/bzip2.html
COPY bzip2/* .
RUN curl -L https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz -o bzip2-1.0.8.tar.gz && \
    tar xzf bzip2-1.0.8.tar.gz && \
    cd bzip2-1.0.8 && \
    mv ../Makefile . && mv ../Makefile-libbz2_so . && \
    make -f Makefile-libbz2_so -j$(nproc --all) && \
    make clean && \
    make -j$(nproc --all) && \
    make PREFIX=/toolchain/i486-linux-musl/usr install && \
    cp -av libbz2.so* /toolchain/i486-linux-musl/usr/lib/ && \
    cd .. && rm -rf bzip2-1.0.8.tar.gz bzip2-1.0.8 && \
    mv libbz2.pc /toolchain/i486-linux-musl/usr/lib/pkgconfig/

# Download, extract, configure, build and install readline
RUN curl https://ftp.gnu.org/gnu/readline/readline-8.1.2.tar.gz -o readline-8.1.2.tar.gz && \
    tar xzf readline-8.1.2.tar.gz && \
    cd readline-8.1.2 && \
    ./configure --prefix=/usr --host=i486-linux-musl \
        --with-curses --enable-multibyte --disable-install-examples \
        CFLAGS="-Os -g0 -march=i486 -mcpu=i486 -mtune=i486"  \
        CXXFLAGS="-g0 -Os -march=i486 -mcpu=i486 -mtune=i486" && \
    make -j$(nproc --all) && \
    make DESTDIR=/toolchain/i486-linux-musl install && \
    cd .. && rm -rf readline-8.1.2.tar.gz readline-8.1.2

# Download, extract, configure, build and install PCRE
RUN curl -L https://sourceforge.net/projects/pcre/files/pcre/8.45/pcre-8.45.tar.bz2/download -o pcre-8.45.tar.bz2 && \
    tar xjf pcre-8.45.tar.bz2 && \
    cd pcre-8.45 && \
    ./configure \
        CFLAGS="-Os -g0 -march=i486 -mcpu=i486 -mtune=i486" \
        CXXFLAGS="-g0 -Os -march=i486 -mcpu=i486 -mtune=i486" \
        --prefix=/usr --host=i486-linux-musl \
        --enable-unicode-properties \
        --enable-pcre16 \
        --enable-pcre32 \
        --enable-pcregrep-libz \
        --enable-pcregrep-readline \
        --enable-pcregrep-libbz2 && \
    make -j$(nproc --all) && \
    make DESTDIR=/toolchain/i486-linux-musl install && \
    cd .. && rm -rf pcre-8.45.tar.bz2 pcre-8.45

# Download, extract, configure, build and install libffi
RUN curl -L https://github.com/libffi/libffi/releases/download/v3.4.2/libffi-3.4.2.tar.gz -o libffi-3.4.2.tar.gz && \
    tar xzf libffi-3.4.2.tar.gz && \
    cd libffi-3.4.2 && \
    ./configure \
        CFLAGS="-Os -g0 -march=i486 -mcpu=i486 -mtune=i486" \
        CXXFLAGS="-g0 -Os -march=i486 -mcpu=i486 -mtune=i486" \
        --prefix=/usr --host=i486-linux-musl && \
    make -j$(nproc --all) && \
    make DESTDIR=/toolchain/i486-linux-musl install && \
    cd .. && rm -rf libffi-3.4.2 libffi-3.4.2.tar.gz

# Download, extract, configure, build and install glib
COPY i486.cross .
RUN apk add --update --no-cache --virtual .glib-deps meson ninja && \
    curl -L https://gitlab.gnome.org/GNOME/glib/-/archive/2.71.1/glib-2.71.1.tar.bz2 -o glib-2.71.1.tar.bz2  && \
    tar xjf glib-2.71.1.tar.bz2 && \
    cd glib-2.71.1 && \
    meson setup --cross-file ../i486.cross builddir && \
    ninja -C builddir && \
    meson install -C builddir && \
    cd .. && rm -rf glib-2.71.1 glib-2.71.1.tar.bz2 i486.cross && \
    apk del .glib-deps

# Remove all situational build dependencies
RUN apk del .situational-build-deps

# Set ARCH and CROSS_COMPILE environment variables
ENV ARCH="x86"
ENV CROSS_COMPILE="i486-linux-musl-"

ENTRYPOINT "/bin/sh"
