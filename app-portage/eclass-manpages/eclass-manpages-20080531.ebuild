# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-portage/eclass-manpages/eclass-manpages-20080531.ebuild,v 1.2 2008/06/02 05:57:55 zmedico Exp $

EAPI="prefix"

DESCRIPTION="collection of Gentoo eclass manpages"
HOMEPAGE="http://www.gentoo.org/"
SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~x86-solaris"
IUSE=""

DEPEND=""
RDEPEND="!app-portage/portage-manpages"

S=${WORKDIR}

src_compile() {
	local e
	for e in "${ECLASSDIR}"/*.eclass ; do
		awk -f "${FILESDIR}"/eclass-to-manpage.awk ${e} > ${e##*/}.5 || rm -f ${e##*/}.5
	done
}

src_install() {
	doman *.5 || die
}
