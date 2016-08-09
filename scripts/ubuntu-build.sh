#!/bin/bash
# set -x
set -e
usage () {
    echo "$0 [<-s|--sersfx> <numerical_series_suffix>] [-d|--dev]"
    exit $1
}

#
#  MAIN
#
BDIR=build-ubuntu
SER_SFX=1
# a development release build automatically the new 'changelog' chapter
# an official release use 'changelog' as is except for change serie name
IS_DEV_RELEASE=n
while [ "$1" != "" ]; do
    case $1 in
        -d|--dev)
            IS_DEV_RELEASE=y
            ;;
        -s|--sersfx)
            SER_SFX=$2
            shift
            ;;
        *)
            usage 1
            ;;
    esac
    shift
done

if [ "$DEBEMAIL" == "" -o "$DEBFULLNAME" == "" ]; then
    echo "DEBEMAIL and DEBFULLNAME variables must be set before run this script"
    exit 1
fi

if ! gpg --list-secret-keys "${DEBFULLNAME} <${DEBEMAIL}>" >/dev/null 2>&1 ; then
    echo "gpg secret key not found for '${DEBFULLNAME} <${DEBEMAIL}>' address"
    exit 2
fi

PKG_NAME=freerdp
PKG_DATE="$(date -R)"
VER_MAJ="$(grep 'set(FREERDP_VERSION_MAJOR' CMakeLists.txt | sed 's/set(FREERDP_VERSION_[^"]*"//g;s/".*//g')"
VER_MIN="$(grep 'set(FREERDP_VERSION_MINOR' CMakeLists.txt | sed 's/set(FREERDP_VERSION_[^"]*"//g;s/".*//g')"
VER_REV="$(grep 'set(FREERDP_VERSION_REVISION' CMakeLists.txt | sed 's/set(FREERDP_VERSION_[^"]*"//g;s/".*//g')"
VER_SFX="$(grep 'set(FREERDP_VERSION_SUFFIX' CMakeLists.txt | sed 's/set(FREERDP_VERSION_[^"]*"//g;s/".*//g')"
VER_DATE="$(date +%Y%m%d)"

PKG_VER="${VER_MAJ}.${VER_MIN}.${VER_REV}~${VER_SFX}~git${VER_DATE}+dfsg"
PKG_DIR="${PKG_NAME}_${PKG_VER}"

mkdir -p ${BDIR}
rm -rf ${BDIR}/*

# exports repo without .git folder and other operative system clients
git archive --format tar --prefix "${BDIR}/${PKG_DIR}/" HEAD | \
    tar xv --exclude="*/client/Android/"  --exclude="*/client/Android" \
           --exclude="*/client/iOS/"      --exclude="*/client/iOS" \
           --exclude="*/client/Mac/"      --exclude="*/client/Mac" \
           --exclude="*/client/Windows/*" --exclude="*/client/Windows"

# Override original ChangeLog with git logs (maybe necessary for debian policy ?
git --no-pager log --format="%ai %aN (%h) %n%n%x09*%w(68,0,10) %s%d%n" > "${BDIR}/${PKG_DIR}/ChangeLog"

# NOTE: artificially files date reconstruction is skipped


if [ "$IS_DEV_RELEASE" = "y" ]; then
    cat <<EOF > ${BDIR}/release.template
${PKG_NAME} (${PKG_VER}-1#SeRiE#${SER_SFX}) #SeRiE#; urgency=medium

  * New upstream release.

 -- ${DEBFULLNAME} <${DEBEMAIL}>  ${PKG_DATE}

EOF
fi

cat ${BDIR}/${PKG_DIR}/debian/changelog >> ${BDIR}/release.template
cd ${BDIR}/${PKG_DIR}/
tar zcvf "../${PKG_NAME}_${PKG_VER}.orig.tar.gz" .
for serie in yakkety wily xenial trusty; do
    sed "s/#SeRiE#/$serie/g" < ../release.template >debian/changelog
    debuild -S -sa
done
cd -
rm ${BDIR}/release.template

echo "now cd in ${BDIR} directory and run:"
echo "dput <your-ppa-address> *.changes"

exit 0
