# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/imlib2/imlib2-1.4.2-r1.ebuild,v 1.8 2010/01/22 17:04:39 ssuominen Exp $

EAPI=1
inherit enlightenment toolchain-funcs eutils libtool

MY_P=${P/_/-}
DESCRIPTION="Version 2 of an advanced replacement library for libraries like libXpm"
HOMEPAGE="http://www.enlightenment.org/"


IUSE="X bzip2 gif jpeg mmx mp3 png tiff zlib"

DEPEND="=media-libs/freetype-2*
	bzip2? ( app-arch/bzip2 )
	zlib? ( sys-libs/zlib )
	gif? ( >=media-libs/giflib-4.1.0 )
	png? ( >=media-libs/libpng-1.2.1 )
	jpeg? ( media-libs/jpeg:0 )
	tiff? ( >=media-libs/tiff-3.5.5 )
	X? ( x11-libs/libXext x11-proto/xextproto )
	mp3? ( media-libs/libid3tag )"

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${P}-CVE-2008-5187.patch #248057
	sed -i '/bumpmap_la_LIBADD/s:$: -lm:' src/modules/filters/Makefile.in #276285

	epatch "${FILESDIR}"/${P}-darwin-bundle.patch #272426
	elibtoolize # for Darwin bundles
}

src_compile() {
	# imlib2 has diff configure options for x86/amd64 mmx
	local myconf=""
	if [[ ${CHOST} == x86_64-* ]] ; then
		myconf="$(use_enable mmx amd64) --disable-mmx"
	else
		myconf="--disable-amd64 $(use_enable mmx)"
	fi

	[[ $(gcc-major-version) -ge 4 ]] && myconf="${myconf} --enable-visibility-hiding"

	export MY_ECONF="
		$(use_with X x) \
		$(use_with jpeg) \
		$(use_with png) \
		$(use_with tiff) \
		$(use_with gif) \
		$(use_with zlib) \
		$(use_with bzip2) \
		$(use_with mp3 id3) \
		${myconf} \
	"
	enlightenment_src_compile
}
