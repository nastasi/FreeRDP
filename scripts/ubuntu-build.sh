#!/bin/bash
PKG_NAME=freerdp
VER_MAJ="$(grep 'set(FREERDP_VERSION_MAJOR' CMakeLists.txt | sed 's/set(FREERDP_VERSION_[^"]*"//g;s/".*//g')"
VER_MIN="$(grep 'set(FREERDP_VERSION_MINOR' CMakeLists.txt | sed 's/set(FREERDP_VERSION_[^"]*"//g;s/".*//g')"
VER_REV="$(grep 'set(FREERDP_VERSION_REVISION' CMakeLists.txt | sed 's/set(FREERDP_VERSION_[^"]*"//g;s/".*//g')"
VER_SFX="$(grep 'set(FREERDP_VERSION_SUFFIX' CMakeLists.txt | sed 's/set(FREERDP_VERSION_[^"]*"//g;s/".*//g')"
VER_DATE="$(date +%Y%m%d)"

PKG_DIR="${PKG_NAME}_${VER_MAJ}.${VER_MIN}.${VER_REV}~${VER_SFX}~git${VER_DATE}+dfsg"

mkdir -p build
rm -rf build/*

git archive --format tar --prefix "build/${PKG_DIR}/" HEAD | \
    tar xv --exclude="*/client/Android/"  --exclude="*/client/Android" \
           --exclude="*/client/Mac/"      --exclude="*/client/Mac" \
           --exclude="*/client/Windows/*" --exclude="*/client/Windows"
