#!/bin/bash
set -eu

getnumproc() {
which getconf >/dev/null 2>/dev/null && {
	getconf _NPROCESSORS_ONLN 2>/dev/null || getconf NPROCESSORS_ONLN 2>/dev/null || echo 1;
} || echo 1;
};

numproc=`getnumproc`

BINUTILS="ftp://ftp.gnu.org/gnu/binutils/binutils-2.34.tar.bz2"
GCC="ftp://ftp.gnu.org/gnu/gcc/gcc-10.1.0/gcc-10.1.0.tar.gz"
MAKE="ftp://ftp.gnu.org/gnu/make/make-4.2.1.tar.bz2"
NEWLIB="ftp://sourceware.org/pub/newlib/newlib-3.3.0.tar.gz"
TCFLAG="-g -O2 -D_MIPS_SZLONG=32 -D_MIPS_SZINT=32 -mabi=32 -march=vr4300 -mtune=vr4300 -mfix4300"
TCXXFLAG="-g -O2 -D_MIPS_SZLONG=32 -D_MIPS_SZINT=32 -mabi=32 -march=vr4300 -mtune=vr4300 -mfix4300"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${SCRIPT_DIR} && mkdir -p {stamps,tarballs}

export PATH="${PATH}:${SCRIPT_DIR}/bin"

if [ ! -f stamps/binutils-download ]; then
  wget "${BINUTILS}" -O "tarballs/$(basename ${BINUTILS})"
  touch stamps/binutils-download
fi

if [ ! -f stamps/binutils-extract ]; then
  mkdir -p binutils-{build,source}
  tar -xf tarballs/$(basename ${BINUTILS}) -C binutils-source --strip 1
  touch stamps/binutils-extract
fi

if [ ! -f stamps/binutils-configure ]; then
  pushd binutils-build
  ../binutils-source/configure \
    --prefix="${SCRIPT_DIR}" \
    --with-lib-path="${SCRIPT_DIR}/lib" \
    --target=mips64-elf --with-arch=vr4300 \
    --enable-64-bit-bfd \
    --enable-plugins \
    --enable-shared \
    --disable-gold \
    --disable-multilib \
    --disable-nls \
    --disable-rpath \
    --disable-static \
    --disable-werror
  popd

  touch stamps/binutils-configure
fi

if [ ! -f stamps/binutils-build ]; then
  pushd binutils-build
  make -j${numproc}
  popd

  touch stamps/binutils-build
fi

if [ ! -f stamps/binutils-install ]; then
  pushd binutils-build
  make install
  popd

  touch stamps/binutils-install
fi

if [ ! -f stamps/gcc-download ]; then
  wget "${GCC}" -O "tarballs/$(basename ${GCC})"
  touch stamps/gcc-download
fi

if [ ! -f stamps/gcc-extract ]; then
  mkdir -p gcc-{build,source}
  tar -xf tarballs/$(basename ${GCC}) -C gcc-source --strip 1
  touch stamps/gcc-extract
fi

if [ ! -f stamps/gcc-configure ]; then
  pushd gcc-build
  ../gcc-source/configure \
    --prefix="${SCRIPT_DIR}" \
    --target=mips64-elf --with-arch=vr4300 \
    --enable-languages=c,c++ --without-headers --with-newlib \
    --with-gnu-as=${SCRIPT_DIR}/bin/mips64-elf-as \
    --with-gnu-ld=${SCRIPT_DIR}/bin/mips64-elf-ld \
    --enable-checking=release \
    --enable-shared \
    --enable-shared-libgcc \
    --disable-decimal-float \
    --disable-gold \
    --disable-libatomic \
    --disable-libgomp \
    --disable-libitm \
    --disable-libquadmath \
    --disable-libquadmath-support \
    --disable-libsanitizer \
    --disable-libssp \
    --disable-libunwind-exceptions \
    --disable-libvtv \
    --disable-multilib \
    --disable-nls \
    --disable-rpath \
    --disable-threads \
    --disable-win32-registry \
    --enable-lto \
    --enable-plugin \
    --enable-static \
    --without-included-gettext
  popd

  touch stamps/gcc-configure
fi

if [ ! -f stamps/gcc-build ]; then
  pushd gcc-build
  make all-gcc -j${numproc}
  popd

  touch stamps/gcc-build
fi

if [ ! -f stamps/libgcc-build ]; then
  pushd gcc-build
  make all-target-libgcc \
    CFLAGS_FOR_TARGET="${TCFLAG}" \
    CXXFLAGS_FOR_TARGET="${TCXXFLAG}" \
    -j${numproc}
  popd

  touch stamps/libgcc-build
fi

if [ ! -f stamps/gcc-install ]; then
  pushd gcc-build
  make install-gcc
  popd

  touch stamps/gcc-install
fi

if [ ! -f stamps/libgcc-install ]; then
  pushd gcc-build
  make install-target-libgcc
  popd

  touch stamps/libgcc-install
fi

if [ ! -f stamps/newlib-download ]; then
  wget "${NEWLIB}" -O "tarballs/$(basename ${NEWLIB})"
  touch stamps/newlib-download
fi

if [ ! -f stamps/newlib-extract ]; then
  mkdir -p newlib-{build,source}
  tar -xf tarballs/$(basename ${NEWLIB}) -C newlib-source --strip 1
  touch stamps/newlib-extract
fi

if [ ! -f stamps/newlib-install ]; then
  pushd newlib-build
  CFLAGS_FOR_TARGET="${TCFLAG}" \
    CXXFLAGS_FOR_TARGET="${TCXXFLAG}" \
    ../newlib-source/configure
    --target=mips64-elf --prefix=${SCRIPT_DIR} \
    --with-cpu=mips64vr4300 \
    --disable-threads \
    --disable-libssp \
    --disable-werror \
  make -j${numproc}
  make install
  popd

  touch stamps/newlib-install
fi

rm -rf tarballs
rm -rf *-source
rm -rf *-build
rm -rf stamps
rm -rf build-toolchain.sh
exit 0
