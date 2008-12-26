# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emacs/ddskk/ddskk-13.1.ebuild,v 1.4 2008/08/27 08:32:17 ulm Exp $

EAPI="prefix"

inherit elisp

DESCRIPTION="One Japanese input methods on Emacs"
HOMEPAGE="http://openlab.ring.gr.jp/skk/"
SRC_URI="http://openlab.ring.gr.jp/skk/maintrunk/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64-linux ~x86-linux ~ppc-macos"
IUSE=""

DEPEND=">=app-emacs/apel-10.7"
RDEPEND="${DEPEND}
	|| ( app-i18n/skk-jisyo virtual/skkserv )"

SITEFILE=50ddskk-gentoo.el

src_unpack() {
	unpack ${A}
	find . -type f | xargs sed -i -e 's%/usr/local%'"${EPREFIX}"'/usr%g' || die
}

src_compile() {
	emake < /dev/null || die "emake failed"
	emake info < /dev/null || die "emake info failed"
	#cd nicola
	#make < /dev/null || die
	cd "${S}/tut-code"
	BYTECOMPFLAGS="${BYTECOMPFLAGS} -L .."
	elisp-compile *.el || die "elisp-compile failed"
}

src_install () {
	elisp-install ${PN} *.el* nicola/*.el* tut-code/*.el* || die "elisp-install failed"
	elisp-site-file-install "${FILESDIR}/${SITEFILE}" || die "elisp-site-file-install failed"

	insinto /usr/share/skk
	doins etc/*SKK.tut* etc/skk.xpm

	dodoc READMEs/* ChangeLog*
	doinfo doc/skk.info*

	#docinto nicola
	#dodoc nicola/ChangeLog* nicola/README*
	docinto tut-code
	dodoc tut-code/README.tut
}
