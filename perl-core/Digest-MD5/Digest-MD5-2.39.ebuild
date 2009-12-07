# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/perl-core/Digest-MD5/Digest-MD5-2.39.ebuild,v 1.3 2009/12/04 13:39:57 tove Exp $

EAPI=2

MODULE_AUTHOR=GAAS
inherit perl-module

DESCRIPTION="MD5 message digest algorithm"

SLOT="0"
KEYWORDS="~ppc-aix ~x86-interix ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE=""

RDEPEND="virtual/perl-digest-base"
DEPEND="${RDEPEND}"

SRC_TEST=do
mydoc="rfc*.txt"
