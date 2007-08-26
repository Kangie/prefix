# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/curl/curl-7.15.5-r1.ebuild,v 1.8 2007/08/25 14:34:19 vapier Exp $

EAPI="prefix"

# NOTE: If you bump this ebuild, make sure you bump dev-python/pycurl!

inherit libtool eutils

DESCRIPTION="A Client that groks URLs"
HOMEPAGE="http://curl.haxx.se/"
SRC_URI="http://curl.haxx.se/download/${P}.tar.bz2"

LICENSE="MIT X11"
SLOT="0"
KEYWORDS="~amd64 ~ppc-macos ~x86 ~x86-macos ~x86-solaris"
IUSE="ssl ipv6 ldap ares gnutls idn kerberos test"

RDEPEND="gnutls? ( net-libs/gnutls )
	ssl? ( !gnutls? ( dev-libs/openssl ) )
	ldap? ( net-nds/openldap )
	idn? ( net-dns/libidn )
	ares? ( net-dns/c-ares )
	kerberos? ( virtual/krb5 )"

DEPEND="${RDEPEND}
	test? (
		sys-apps/diffutils
		dev-lang/perl
	)"
# used - but can do without in self test: net-misc/stunnel

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}"/${PN}-7.15-strip-ldflags.patch
	epatch "${FILESDIR}"/curl-7.15.1-test62.patch
	epatch "${FILESDIR}"/libcurl-gnutlscert.patch
	elibtoolize
}

src_compile() {

	myconf="$(use_enable ldap)
		$(use_with idn libidn)
		$(use_enable kerberos gssapi)
		$(use_enable ipv6)
		--enable-http
		--enable-ftp
		--enable-gopher
		--enable-file
		--enable-dict
		--enable-manual
		--enable-telnet
		--enable-nonblocking
		--enable-largefile"

	if use ipv6 && use ares; then
		ewarn "c-ares support disabled because it is incompatible with ipv6."
		myconf="${myconf} --disable-ares"
	else
		myconf="${myconf} $(use_enable ares)"
	fi

	if use gnutls; then
		myconf="${myconf} --without-ssl --with-gnutls=${EPREFIX}/usr"
	elif use ssl; then
		myconf="${myconf} --without-gnutls --with-ssl=${EPREFIX}/usr"
	else
		myconf="${myconf} --without-gnutls --without-ssl"
	fi

	if use kerberos; then
	   myconf="${myconf} --with-gssapi=${EPREFIX}/usr"
	fi

	econf ${myconf} || die 'configure failed'
	emake || die "install failed for current version"
}

src_install() {
	make DESTDIR="${D}" install || die "installed failed for current version"

	insinto /usr/share/aclocal
	doins docs/libcurl/libcurl.m4

	dodoc CHANGES README
	dodoc docs/FEATURES docs/INTERNALS
	dodoc docs/MANUAL docs/FAQ docs/BUGS docs/CONTRIBUTE
}
