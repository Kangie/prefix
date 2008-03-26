# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-libs/openssl/openssl-0.9.8g-r1.ebuild,v 1.1 2008/03/25 00:27:14 cardoe Exp $

EAPI="prefix"

inherit eutils flag-o-matic toolchain-funcs

DESCRIPTION="Toolkit for SSL v2/v3 and TLS v1"
HOMEPAGE="http://www.openssl.org/"
SRC_URI="mirror://openssl/source/${P}.tar.gz"

LICENSE="openssl"
SLOT="0"
KEYWORDS="~ppc-aix ~x86-freebsd ~ia64-hpux ~x86-interix ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="bindist emacs gmp kerberos sse2 test zlib"

RDEPEND="gmp? ( dev-libs/gmp )
	zlib? ( sys-libs/zlib )
	kerberos? ( app-crypt/mit-krb5 )"
DEPEND="${RDEPEND}
	sys-apps/diffutils
	>=dev-lang/perl-5
	test? ( sys-devel/bc )"
PDEPEND="app-misc/ca-certificates"

src_unpack() {
	unpack ${A}
	cd "${S}"

# this patch kills Darwin, but seems not necessary on Solaris and Linux
#	epatch "${FILESDIR}"/${PN}-0.9.7e-gentoo.patch
	epatch "${FILESDIR}"/${PN}-0.9.7-alpha-default-gcc.patch
	epatch "${FILESDIR}"/${PN}-0.9.8b-parallel-build.patch
	epatch "${FILESDIR}"/${PN}-0.9.8-make-engines-dir.patch
	epatch "${FILESDIR}"/${PN}-0.9.8-toolchain.patch
	epatch "${FILESDIR}"/${PN}-0.9.8b-doc-updates.patch
	epatch "${FILESDIR}"/${PN}-0.9.8-makedepend.patch #149583
	epatch "${FILESDIR}"/${PN}-0.9.8e-make.patch #146316
	epatch "${FILESDIR}"/${PN}-0.9.8e-bsd-sparc64.patch
	epatch "${FILESDIR}"/${PN}-0.9.8g-sslv3-no-tlsext.patch

	epatch "${FILESDIR}"/${PN}-0.9.8g-engines-installnames.patch
	epatch "${FILESDIR}"/${PN}-0.9.8g-darwin64.patch
	epatch "${FILESDIR}"/${PN}-0.9.8g-interix.patch
	epatch "${FILESDIR}"/${PN}-0.9.8g-interix-3.5.patch

	# remove -arch for darwin
	sed -i '/^"darwin/s,-arch [^ ]\+,,g' Configure

	# allow openssl to be cross-compiled
	cp "${FILESDIR}"/gentoo.config-0.9.8 gentoo.config || die "cp cross-compile failed"
	eprefixify gentoo.config
	chmod a+rx gentoo.config

	# Don't build manpages if we don't want them
	has noman FEATURES \
		&& sed -i '/^install:/s:install_docs::' Makefile.org \
		|| sed -i '/^MANDIR=/s:=.*:='"${EPREFIX}"'/usr/share/man:' Makefile.org

	# Try to derice users and work around broken ass toolchains
	if [[ $(gcc-major-version) == "3" ]] ; then
		filter-flags -fprefetch-loop-arrays -freduce-all-givs -funroll-loops
		[[ $(tc-arch) == "ppc64" ]] && replace-flags -O? -O
	fi
	[[ $(tc-arch) == ppc* ]] && append-flags -fno-strict-aliasing

	[[ $(tc-arch) == *-macos   ]] ||
	[[ $(tc-arch) == *-aix     ]] ||
	[[ $(tc-arch) == *-interix ]] ||
		append-flags -Wa,--noexecstack

	# using a library directory other than lib requires some magic
	sed -i \
		-e "s+\(\$(INSTALL_PREFIX)\$(INSTALLTOP)\)/lib+\1/$(get_libdir)+g" \
		-e "s+libdir=\$\${exec_prefix}/lib+libdir=\$\${exec_prefix}/$(get_libdir)+g" \
		Makefile.org engines/Makefile \
		|| die "sed failed"

	# avoid waiting on terminal input forever when spitting
	# 64bit warning message.
	[[ ${CHOST} == *-hpux* ]] && sed -i -e 's,stty,true,g' -e 's,read waste,true,g' config

	./config --test-sanity || die "I AM NOT SANE"
}

src_compile() {
	unset APPS #197996

	tc-export CC AR RANLIB

	# Clean out patent-or-otherwise-encumbered code
	# Camellia: Royalty Free            http://en.wikipedia.org/wiki/Camellia_(cipher)
	# IDEA:     5,214,703 25/05/2010    http://en.wikipedia.org/wiki/International_Data_Encryption_Algorithm
	# EC:       ????????? ??/??/2015    http://en.wikipedia.org/wiki/Elliptic_Curve_Cryptography
	# MDC2:     Expired                 http://en.wikipedia.org/wiki/MDC-2
	# RC5:      5,724,428 03/03/2015    http://en.wikipedia.org/wiki/RC5

	use_ssl() { use $1 && echo "enable-${2:-$1} ${*:3}" || echo "no-${2:-$1}" ; }
	echoit() { echo "$@" ; "$@" ; }

	local krb5=$(has_version app-crypt/mit-krb5 && echo "MIT" || echo "Heimdal")

	case $CHOST in
		sparc-sun-solaris*)
			# openssl doesn't grok this setup, and guesses
			# the architecture wrong, just disable asm for now
			confopts="${confopts} no-asm"
		;;
	esac

	local sslout=$(./gentoo.config)
	einfo "Use configuration ${sslout:-(openssl knows best)}"
	local config="Configure"
	[[ -z ${sslout} ]] && config="config"
	echoit \
	./${config} \
		${sslout} \
		$(use sse2 || echo "no-sse2") \
		enable-camellia \
		$(use_ssl !bindist ec) \
		$(use_ssl !bindist idea) \
		enable-mdc2 \
		$(use_ssl !bindist rc5) \
		enable-tlsext \
		$(use_ssl gmp) \
		$(use_ssl kerberos krb5 --with-krb5-flavor=${krb5}) \
		$(use_ssl zlib) \
		$(use_ssl zlib zlib-dynamic) \
		--prefix="${EPREFIX}"/usr \
		--openssldir="${EPREFIX}"/etc/ssl \
		shared threads \
		|| die "Configure failed"

	if [[ ${CHOST} == i?86*-*-linux* || ${CHOST} == i?86*-*-freebsd* ]]; then
		# does not compile without optimization on x86-linux and x86-fbsd
		filter-flags -O0
		is-flagq -O* || append-flags -O1
	fi

	# Clean out hardcoded flags that openssl uses
	local CFLAG=$(grep ^CFLAG= Makefile | LC_ALL=C sed \
		-e 's:^CFLAG=::' \
		-e 's:-fomit-frame-pointer ::g' \
		-e 's:-O[0-9] ::g' \
		-e 's:-march=[-a-z0-9]* ::g' \
		-e 's:-mcpu=[-a-z0-9]* ::g' \
		-e 's:-m[a-z0-9]* ::g' \
	)
	sed -i \
		-e "/^CFLAG/s|=.*|=${CFLAG} ${CFLAGS}|" \
		-e "/^SHARED_LDFLAGS=/s|$| ${LDFLAGS}|" \
		Makefile || die

	# depend is needed to use $confopts
	# rehash is needed to prep the certs/ dir
	emake -j1 depend || die "depend failed"
	emake all || die "make all failed"
	emake rehash || die "make rehash failed"
}

src_test() {
	# make sure sandbox doesnt die on *BSD
	addpredict /dev/crypto

	emake -j1 test || die "make test failed"
}

src_install() {
	emake -j1 INSTALL_PREFIX="${D}" install || die
	dodoc CHANGES* FAQ NEWS README doc/*.txt
	dohtml doc/*

	if use emacs ; then
		insinto /usr/share/emacs/site-lisp
		doins doc/c-indentation.el
	fi

	# create the certs directory
	dodir /etc/ssl/certs
	cp -RP certs/* "${ED}"/etc/ssl/certs/ || die "failed to install certs"
	rm -r "${ED}"/etc/ssl/certs/{demo,expired}

	# Namespace openssl programs to prevent conflicts with other man pages
	cd "${ED}"/usr/share/man
	local m d s
	for m in $(find . -type f | xargs grep -L '#include') ; do
		d=${m%/*} ; d=${d#./} ; m=${m##*/}
		[[ ${m} == openssl.1* ]] && continue
		[[ -n $(find -L ${d} -type l) ]] && die "erp, broken links already!"
		mv ${d}/{,ssl-}${m}
		ln -s ssl-${m} ${d}/openssl-${m}
		# locate any symlinks that point to this man page ... we assume
		# that any broken links are due to the above renaming
		for s in $(find -L ${d} -type l) ; do
			s=${s##*/}
			rm -f ${d}/${s}
			ln -s ssl-${m} ${d}/ssl-${s}
			ln -s ssl-${s} ${d}/openssl-${s}
		done
	done
	[[ -n $(find -L ${d} -type l) ]] && die "broken manpage links found :("

	diropts -m0700
	keepdir /etc/ssl/private
}

pkg_preinst() {
	preserve_old_lib /usr/$(get_libdir)/lib{crypto,ssl}$(get_libname 0.9.6)
	preserve_old_lib /usr/$(get_libdir)/lib{crypto,ssl}$(get_libname 0.9.7)
}

pkg_postinst() {
	preserve_old_lib_notify /usr/$(get_libdir)/lib{crypto,ssl}$(get_libname 0.9.6)
	preserve_old_lib_notify /usr/$(get_libdir)/lib{crypto,ssl}$(get_libname 0.9.7)

	if [[ ${CHOST} == i686* ]] ; then
		ewarn "Due to the way openssl is architected, you cannot"
		ewarn "switch between optimized versions without breaking"
		ewarn "ABI.  The default i686 0.9.8 ABI was an unoptimized"
		ewarn "version with horrible performance.  This version uses"
		ewarn "the optimized ABI.  If you experience segfaults when"
		ewarn "using ssl apps (like openssh), just re-emerge the"
		ewarn "offending package."
	fi
}
