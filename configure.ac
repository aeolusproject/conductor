AC_INIT([aeolus-conductor], [0.0.3], [aeolus-devel@lists.fedoraproject.org])
AM_INIT_AUTOMAKE([-Wall -Werror foreign -Wno-portability tar-pax])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_MACRO_DIR([m4])

AC_PROG_CXX
AC_PROG_CC
AC_PROG_LIBTOOL
AC_LANG([C++])

AC_ARG_ENABLE(local,
  [  --enable-local   Set this flag if you are planning to run the conductor without installing it.],
  [  CONDUCTOR_INSTALL_DIR=`pwd`/src ], [  CONDUCTOR_INSTALL_DIR=$datadir/aeolus-conductor ])
AC_SUBST(CONDUCTOR_INSTALL_DIR)

dnl
dnl check for classads-devel
dnl

CLASSADS_REQUIRED=1.0.4

AC_ARG_WITH([classads], AC_HELP_STRING([--with-classads=@<:@PFX@:>@],
            [classads location]))

if test "x$with_classads" = xno ; then
    AC_MSG_CHECKING([for classads libraries >= $CLASSADS_REQUIRED])
    AC_MSG_ERROR([classads >= $CLASSADS_REQUIRED is required for conductor])
elif test "x$with_classads" = "x"; then
    fail=0
    AC_CHECK_HEADERS([classad/classad_distribution.h],, [fail=1],[])
    if test $fail = 1; then
       AC_MSG_ERROR([You must install the classads development package to compile the conductor])
    fi
fi

PKG_CHECK_MODULES(GLIB, glib-2.0 >= 2.18)
PKG_CHECK_MODULES(SOUP, libsoup-2.4)
PKG_CHECK_MODULES(XML, libxml-2.0)
PKG_CHECK_MODULES(GTHREAD, gthread-2.0)
PKG_CHECK_MODULES(REST, rest-0.6)

# If using gcc and default CFLAGS, enable some warnings.
test x"$ac_ct_CC:$CFLAGS" = 'xgcc:-g -O2' \
  && CFLAGS="$CFLAGS -Wshadow -Wall -Werror"

AC_CONFIG_FILES([Makefile aeolus-conductor.spec])
AC_OUTPUT(src/classad_plugin/Makefile)

