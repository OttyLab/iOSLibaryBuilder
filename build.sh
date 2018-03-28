#!/bin/bash

#
# Based on https://github.com/sinofool/build-libcurl-ios
#

# curl
curl -OL http://curl.haxx.se/download/curl-7.57.0.tar.gz && \
	tar -xzf curl-7.57.0.tar.gz

# jansson
curl -O http://www.digip.org/jansson/releases/jansson-2.11.tar.gz && \
    tar -xzf jansson-2.11.tar.gz

TMP_DIR=$(pwd)/usr

function build_for_arch() {
    ARCH=$1
    HOST=$2
    SYSROOT=$3
    PREFIX=$4
    IPHONEOS_DEPLOYMENT_TARGET="9.0"
    export PATH="${DEVROOT}/usr/bin/:${PATH}"
    export CFLAGS="-DCURL_BUILD_IOS -arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${SYSROOT} -miphoneos-version-min=${IPHONEOS_DEPLOYMENT_TARGET} -fembed-bitcode"
    export LDFLAGS="-arch ${ARCH} -isysroot ${SYSROOT}"
    
    pushd `pwd`
    cd curl-7.57.0
    ./configure --disable-shared --enable-static --host="${HOST}" --prefix=${PREFIX} && make -j8 && make install && make clean
    popd

    export CFLAGS="-arch ${ARCH} -pipe -Os -gdwarf-2 -isysroot ${SYSROOT} -miphoneos-version-min=${IPHONEOS_DEPLOYMENT_TARGET} -fembed-bitcode"
    export LDFLAGS="-arch ${ARCH} -isysroot ${SYSROOT}"

    pushd `pwd`
    cd jansson-2.11
    ./configure --host="${HOST}" --prefix=${PREFIX} && make -j8 && make install && make clean
    popd
}

build_for_arch x86_64 x86_64-apple-darwin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk ${TMP_DIR}/x86_64 || exit 2
build_for_arch arm64 arm-apple-darwin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk ${TMP_DIR}/arm64 || exit 3
build_for_arch armv7s armv7s-apple-darwin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk ${TMP_DIR}/armv7s || exit 4
build_for_arch armv7 armv7-apple-darwin /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk ${TMP_DIR}/armv7 || exit 5

mkdir -p ${TMP_DIR}/lib

${DEVROOT}/usr/bin/lipo \
    -arch x86_64 ${TMP_DIR}/x86_64/lib/libcurl.a \
    -arch armv7 ${TMP_DIR}/armv7/lib/libcurl.a \
    -arch armv7s ${TMP_DIR}/armv7s/lib/libcurl.a \
    -arch arm64 ${TMP_DIR}/arm64/lib/libcurl.a \
    -output ${TMP_DIR}/lib/libcurl.a -create

${DEVROOT}/usr/bin/lipo \
    -arch x86_64 ${TMP_DIR}/x86_64/lib/libjansson.a \
    -arch armv7 ${TMP_DIR}/armv7/lib/libjansson.a \
    -arch armv7s ${TMP_DIR}/armv7s/lib/libjansson.a \
    -arch arm64 ${TMP_DIR}/arm64/lib/libjansson.a \
    -output ${TMP_DIR}/lib/libjansson.a -create
