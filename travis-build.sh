#!/bin/bash

set -x

### Install Build Tools #1

DEBIAN_FRONTEND=noninteractive apt -qq update
DEBIAN_FRONTEND=noninteractive apt -qq -yy install --no-install-recommends \
	appstream \
	automake \
	autotools-dev \
	build-essential \
	checkinstall \
	cmake \
	curl \
	devscripts \
	equivs \
	extra-cmake-modules \
	gettext \
	git \
	gnupg2 \
	lintian \
	wget

### Add Neon Sources

wget -qO /etc/apt/sources.list.d/neon-user-repo.list https://raw.githubusercontent.com/Nitrux/iso-tool/development/configs/files/sources.list.neon.user

DEBIAN_FRONTEND=noninteractive apt-key adv --keyserver keyserver.ubuntu.com --recv-keys \
	55751E5D > /dev/null

DEBIAN_FRONTEND=noninteractive apt -qq update

### Install Package Build Dependencies #2
### ISOImageWriter needs ECM > 5.70

DEBIAN_FRONTEND=noninteractive apt -qq -yy install --no-install-recommends \
	libgpg-error-dev \
	libgpgme-dev \
	libgpgmepp-dev \
	libkf5archive-dev \
	libkf5auth-dev \
	libkf5coreaddons-dev \
	libkf5crash-dev \
	libkf5i18n-dev \
	libkf5iconthemes-dev \
	libkf5solid-dev \
	libkf5widgetsaddons-dev \
	libudev-dev \
	pkg-config \
	pkg-kde-tools

DEBIAN_FRONTEND=noninteractive apt -qq -yy install --only-upgrade \
	extra-cmake-modules

### Clone repo.

git clone --single-branch --branch master https://invent.kde.org/utilities/isoimagewriter.git

rm -rf isoimagewriter/{LICENSES,doc,.gitignore,.gitlab-ci.yml,.kde-ci.yml,.travis.yml,Messages.sh,isoimagewriter.kdev4}

### Compile Source

mkdir -p isoimagewriter/build && cd isoimagewriter/build

cmake \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DENABLE_BSYMBOLICFUNCTIONS=OFF \
	-DQUICK_COMPILER=ON \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_SYSCONFDIR=/etc \
	-DCMAKE_INSTALL_LOCALSTATEDIR=/var \
	-DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON \
	-DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON \
	-DCMAKE_INSTALL_RUNSTATEDIR=/run "-GUnix Makefiles" \
	-DCMAKE_VERBOSE_MAKEFILE=ON \
	-DCMAKE_INSTALL_LIBDIR=lib/x86_64-linux-gnu ..

make

### Run checkinstall and Build Debian Package
### DO NOT USE debuild, screw it

>> description-pak printf "%s\n" \
	'ISO Image Writer is a tool to write a .iso file to a USB disk.' \
	'' \
	'It uses KAuth so it does not run as root except when required.' \
	'' \
	'It will verify ISOs from a range of distros to ensure they are' \
	'' \
	'valid compared to the checksums or digital signatures.' \
	''

checkinstall -D -y \
	--install=no \
	--fstrans=yes \
	--pkgname=isoimagewriter \
	--pkgversion=0.8.0 \
	--pkgarch=amd64 \
	--pkgrelease="1" \
	--pkglicense=GPL-3 \
	--pkggroup=kde \
	--pkgsource=isoimagewriter \
	--pakdir=../.. \
	--maintainer=uri_herrera@nxos.org \
	--provides=isoimagewriter \
	--requires="libudev1,libc6,libgcc-s1,libgpgmepp6,libkf5archive5,libkf5authcore5,libkf5coreaddons5,libkf5crash5,libkf5i18n5,libkf5iconthemes5,libkf5solid5,libkf5widgetsaddons5,libqgpgme7,libqt5core5a,libqt5gui5,libqt5network5,libqt5widgets5,libstdc++6" \
	--nodoc \
	--strip=no \
	--stripso=yes \
	--reset-uids=yes \
	--deldesc=yes
