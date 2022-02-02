# syntax=docker/dockerfile:1

FROM alpine:latest

RUN apk add --update --no-cache --virtual .build-deps build-base curl gawk flex bison file git rsync perl texinfo

WORKDIR /src

# Download source tarballs and extract them
RUN curl https://ftp.gnu.org/gnu/binutils/binutils-2.37.tar.bz2 -o binutils.tar.bz2 && tar xjf binutils.tar.bz2 && \
    curl https://ftp.gnu.org/gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz -o gcc.tar.xz && tar xf gcc.tar.xz && \
    curl https://musl.libc.org/releases/musl-1.2.2.tar.gz -o musl.tar.gz && tar xzf musl.tar.gz && \
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
    CFLAGS="-Os -g0" \
    CXXFLAGS="-g0 -Os" \
    LDFLAGS="-s" && \
    make -j$(nproc --all) && \
    make install && \
    cd .. && \
    rm -rf binutils-2.37 build-binutils binutils.tar.bz2

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
    CFLAGS="-Os -g0"  \
    CXXFLAGS="-g0 -Os" \
    LDFLAGS="-s" && \
    make -j$(nproc --all) all-gcc all-target-libgcc

# Configure, build and install i486 optimized musl, then clean up
RUN cd musl-1.2.2 && \
    CC="../build-gcc/gcc/xgcc -B ../build-gcc/gcc" \
    LIBCC="../build-gcc/i486-linux-musl/libgcc/libgcc.a" \
    CFLAGS="-Os -g0 -march=i486 -mcpu=i486 -mtune=i486"  \
    CXXFLAGS="-g0 -Os -march=i486 -mcpu=i486 -mtune=i486" \
    LDFLAGS="-s" \
    ./configure --prefix= --host=i486-linux-musl && \
    make -j$(nproc --all) && \
    make DESTDIR=/toolchain/i486-linux-musl install && \
    cd .. && \
    rm -rf musl-1.2.2 musl.tar.gz

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
    CFLAGS="-Os -g0"  \
    CXXFLAGS="-g0 -Os" \
    LDFLAGS="-s" && \
    make -j$(nproc --all) && \
    make install && \
    cd .. && \
    rm -rf gcc-11.2.0 build-gcc gcc.tar.xz

# Toolchain test
RUN echo "int main() { return 0; }" | i486-linux-musl-gcc -x c --static -o /dev/null - && \
    echo "int main() { return 0; }" | i486-linux-musl-gcc -x c -o /dev/null - && \
    echo "int main() { return 0; }" | i486-linux-musl-g++ -x c++ --static -o /dev/null - && \
    echo "int main() { return 0; }" | i486-linux-musl-g++ -x c++ -o /dev/null -  && \
    echo "int main() { return 0; }" | i486-linux-musl-gcc -x c -o /tmp/c.test - && \
    file /tmp/c.test | grep -q "ELF 32-bit LSB executable" && \
    file /tmp/c.test | grep -q "80386"

# Download, extract, configure, build and install ncurses
# https://www.linuxfromscratch.org/lfs/view/development/chapter06/ncurses.html
RUN curl https://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.3.tar.gz -o ncurses.tar.gz && \
    tar xzf ncurses.tar.gz && \
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
    CFLAGS="-Os -g0 -march=i486 -mcpu=i486 -mtune=i486"  \
    CXXFLAGS="-g0 -Os -march=i486 -mcpu=i486 -mtune=i486" \
    LDFLAGS="-s" && \
    make -j$(nproc --all) && \
    make DESTDIR=/toolchain/i486-linux-musl TIC_PATH=$(pwd)/build/progs/tic install && \
    cd .. && rm -rf ncurses.tar.gz ncurses-6.3 && \
    echo "INPUT(-lncursesw)" > /toolchain/i486-linux-musl/usr/lib/libncurses.so && \
    echo "INPUT(-l:libncursesw.a)" > /toolchain/i486-linux-musl/usr/lib/libncurses.a

# Download, extract, configure, build and install zlib
RUN curl https://zlib.net/zlib-1.2.11.tar.xz -o zlib.tar.xz && \
    tar xf zlib.tar.xz && \
    cd zlib-1.2.11 && \
    CC="i486-linux-musl-gcc" \
    AR="i486-linux-musl-ar" \
    RANLIB="i486-linux-musl-ranlib" \
    CFLAGS="-Os -g0 -march=i486 -mcpu=i486 -mtune=i486"  \
    CXXFLAGS="-g0 -Os -march=i486 -mcpu=i486 -mtune=i486" \
    LDFLAGS="-s" \
    ./configure --prefix=/usr && \
    make -j$(nproc --all) && \
    make DESTDIR=/toolchain/i486-linux-musl install && \
    cd .. && rm -rf zlib.tar.xz zlib-1.2.11

# Remove all dependencies but build-essential
RUN apk del .build-deps

# Set ARCH and CROSS_COMPILE environment variables
ENV ARCH="x86"
ENV CROSS_COMPILE="i486-linux-musl-"

ENTRYPOINT "/bin/sh"
