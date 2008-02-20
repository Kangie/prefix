# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/openmotif/openmotif-2.3.0-r1.ebuild,v 1.6 2008/02/19 07:11:35 ulm Exp $

EAPI="prefix"

inherit eutils flag-o-matic multilib autotools

DESCRIPTION="Open Motif"
HOMEPAGE="http://www.motifzone.org/"
SRC_URI="ftp://ftp.ics.com/openmotif/2.3/${PV}/${P}.tar.gz
	doc? ( http://www.motifzone.net/files/documents/${P}-manual.pdf.tgz )"

LICENSE="MOTIF doc? ( OPL )"
SLOT="0"
KEYWORDS=""
# NEED TO FIX THIS FOR PREFIX (config file in filesdir)
KEYWORDS=""
IUSE="doc examples jpeg png xft"

# make people unmerge motif-config and all previous slots
# since the slotting is finally gone now
RDEPEND="!x11-libs/motif-config
	!x11-libs/lesstif
	!<=x11-libs/openmotif-2.3.0
	x11-libs/libXmu
	x11-libs/libXaw
	x11-libs/libXp
	x11-proto/printproto
	xft? ( x11-libs/libXft )
	jpeg? ( media-libs/jpeg )
	png? ( media-libs/libpng )"
DEPEND="${RDEPEND}
	x11-misc/xbitmaps
	x11-proto/printproto"

PROVIDE="virtual/motif"

pkg_setup() {
	# clean up orphaned cruft left over by motif-config
	local i count=0
	for i in "${EROOT}"usr/bin/{mwm,uil,xmbind} \
		"${EROOT}"usr/include/{Xm,uil,Mrm} \
		"${EROOT}"usr/$(get_libdir)/lib{Xm,Uil,Mrm}.*; do
		if [[ -L "${i}" && $(readlink "${i}") =~ (openmo|less)tif- ]]; then
			einfo "Cleaning up orphaned ${i} symlink ..."
			rm -f "${i}"
		fi
	done

	cd "${EROOT}"usr/share/man
	for i in $(find . -type l); do
		if [[ $(readlink "${i}") =~ -(openmo|less)tif- ]]; then
			(( count++ ))
			rm -f "${i}"
		fi
	done
	[[ ${count} -ne 0 ]] && \
		einfo "Cleaned up ${count} orphaned symlinks in ${EROOT}usr/share/man"
}

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}/${P}-sensitivity-invisible.patch"

	# disable compilation of demo binaries
	sed -i -e 's/^[ \t]*demos//' Makefile.in
}

src_compile() {
	# get around some LANG problems in make (#15119)
	unset LANG

	# bug #80421
	filter-flags -ftracer

	# multilib includes don't work right in this package...
	has_multilib_profile && append-flags "-I$(get_ml_incdir)"

	# feel free to fix properly if you care
	append-flags -fno-strict-aliasing

	econf --with-x \
		--bindir="${EPREFIX}"/usr/$(get_libdir)/openmotif-${SLOT} \
		--libdir="${EPREFIX}"/usr/$(get_libdir)/openmotif-${SLOT} \
		$(use_enable xft) \
		$(use_enable jpeg) \
		$(use_enable png)

	emake -j1 || die "emake failed"
}

src_install() {
	emake -j1 DESTDIR="${D}" install || die "emake install failed"

	newbin "${FILESDIR}"/motif-config-2.3 motif-config
	dosed "s:@@LIBDIR@@:$(get_libdir):g" /usr/bin/motif-config

	# mwm default configs
	insinto /etc/X11/app-defaults
	doins "${FILESDIR}"/Mwm.defaults

	for f in /usr/share/man/man1/mwm.1 /usr/share/man/man4/mwmrc.4; do
		dosed 's:/usr/lib/X11/\(.*system\\&\.mwmrc\):'"${EPREFIX}"'/etc/X11/mwm/\1:g' ${f}
		dosed 's:/usr/lib/X11/app-defaults:'"${EPREFIX}"'/etc/X11/app-defaults:g' ${f}
	done

	dodir /etc/X11/mwm
	mv -f "${ED}"/usr/$(get_libdir)/X11/system.mwmrc "${ED}"/etc/X11/mwm
	dosym /etc/X11/mwm/system.mwmrc /usr/$(get_libdir)/X11/

	if use examples ; then
		dodir /usr/share/doc/${PF}/demos
		mv "${ED}"/usr/share/Xm/* "${ED}"/usr/share/doc/${PF}/demos
	fi
	rm -rf "${ED}"/usr/share/Xm

	# documentation
	dodoc README RELEASE RELNOTES BUGREPORT TODO
	use doc && cp "${WORKDIR}"/*.pdf "${ED}"/usr/share/doc/${PF}
}

pkg_postinst() {
	"${EROOT}"/usr/bin/motif-config -s
}

pkg_postrm() {
	"${EROOT}"/usr/bin/motif-config -s
}
