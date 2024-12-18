#!/bin/bash
set -eu
set -o pipefail

# BUILD SH

# Remember to merge output streams into logs to try to prevent
#       buffering problems with conda build

# Environment notes:
# Generally, environment variables are not inherited into here.

# PREFIX is provided by Conda

TIMESTAMP=$( date '+%Y-%m-%d %H:%M:%S' )
echo "BUILD.SH START $TIMESTAMP"

show()
# Report shell value, aligned
{
  for V in ${*}
  do
    printf "%-13s %s\n" ${V}: ${!V:-unset}
  done
}

{
  echo "python:" $( which python )
  show TIMESTAMP
  show PWD
  show RECIPE_DIR
  show SRC_DIR
  show PREFIX
} > $RECIPE_DIR/build-metadata.log

# Cf. helpers.zsh
if [[ $PLATFORM =~ osx-* ]]
then
  NULL=""
  ZT=""
else
  NULL="--null" ZT="--zero-terminated"
fi
printenv ${NULL} | sort ${ZT} | tr '\0' '\n' > \
                                   $RECIPE_DIR/build-env.log

if ! SDKROOT=$( xcrun --show-sdk-path )
then
  print "Error in xcrun!"
  exit 1
fi
export SDKROOT
show SDKROOT >> $RECIPE_DIR/build-metadata.log

do-configure()
{
  # CONDA_PREFIX should be the installation-time Python location

  export CC=$(  which clang    )
  export CXX=$( which clang++  )
  export FC=$(  which gfortran )
  export CPPFLAGS="-I$CONDA_PREFIX/include"
  export CFLAGS="-Wno-nullability-completeness"
  export LDFLAGS="-L$CONDA_PREFIX/lib -Wl,-rpath -Wl,$CONDA_PREFIX/lib"

  echo
  echo "COMPILERS:"
  show CC CXX FC
  echo
  echo "COMPILER SETTINGS:"
  show CPPFLAGS CFLAGS LDFLAGS
  echo

  echo "CONFIGURE ARGUMENTS:"
  A=(  --prefix=$CONDA_PREFIX
       --enable-R-shlib
       --disable-java
       --without-tcltk
       --without-cairo
       --without-jpeglib
       --without-libtiff
       --without-ICU
       --with-included-gettext
       --without-x
       --without-recommended-packages
       --without-aqua
    )
  # Use fmt for single argument per line
  echo ${A[@]} | fmt -w 5
  echo
  (
    # Subshell for set -x
    set -x
    ./configure ${A[@]}
  )
}

# Configure it!
{
  echo "CONFIGURE R START: $( date '+%Y-%m-%d %H:%M:%S' )"
  do-configure 2>&1
  echo "CONFIGURE R STOP:  $( date '+%Y-%m-%d %H:%M:%S' )"
} | tee $RECIPE_DIR/build-configure.log

# Make it!
{
  echo "MAKE R START: $( date '+%Y-%m-%d %H:%M:%S' )"
  make -j 4 2>&1
  echo "MAKE R STOP:  $( date '+%Y-%m-%d %H:%M:%S' )"
} | tee $RECIPE_DIR/build-make.log

# Install it!
{
  echo "INSTALL R START: $( date '+%Y-%m-%d %H:%M:%S' )"
  make install 2>&1
  echo "INSTALL R STOP:  $( date '+%Y-%m-%d %H:%M:%S' )"
} | tee $RECIPE_DIR/build-install.log

# Test it!
{
  echo "TEST R START: $( date '+%Y-%m-%d %H:%M:%S' )"
  $CONDA_PREFIX/bin/R --version
  $CONDA_PREFIX/bin/R -e 'cat("R-TEST:", 42, "\n")'
  echo "TEST R STOP:  $( date '+%Y-%m-%d %H:%M:%S' )"
} 2>&1 | tee $RECIPE_DIR/build-test.log

echo "BUILD.SH STOP $( date '+%Y-%m-%d %H:%M:%S' )"
