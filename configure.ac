AC_INIT([deltacloud-aggregator], [0.0.2], [deltacloud-devel@lists.fedoraproject.org])
AM_INIT_AUTOMAKE([-Wall -Werror foreign -Wno-portability tar-pax])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])

AC_PROG_CXX
AC_PROG_CC
AC_PROG_LIBTOOL
AC_LANG([C++])

AC_ARG_ENABLE(local,
  [  --enable-local   Set this flag if you are planning to run the aggregator without installing it.],
  [  DELTACLOUD_INSTALL_DIR=`pwd`/src ], [  DELTACLOUD_INSTALL_DIR=$pkgdatadir ])
AC_SUBST(DELTACLOUD_INSTALL_DIR)

# If using gcc and default CFLAGS, enable some warnings.
test x"$ac_ct_CC:$CFLAGS" = 'xgcc:-g -O2' \
  && CFLAGS="$CFLAGS -Wshadow -Wall -Werror"

AC_CONFIG_FILES([Makefile deltacloud-aggregator.spec])
AC_OUTPUT(src/classad_plugin/Makefile)
