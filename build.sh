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

echo
echo "BUILD.SH START $TIMESTAMP"
echo

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

# if ! SDKROOT=$( xcrun --show-sdk-path )
# then
#   print "Error in xcrun!"
#   exit 1
# fi
# export SDKROOT
# show SDKROOT >> $RECIPE_DIR/build-metadata.log

do-configure()
{
  # CONDA_PREFIX should be the installation-time Python location

  # export CC=$(  which clang    )
  # export CXX=$( which clang++  )
  # export FC=$(  which gfortran )
  export CC=$CONDA_PREFIX/bin/gcc
  export CXX=$CONDA_PREFIX/bin/g++
  export FC=$CONDA_PREFIX/bin/gfortran
  export CPPFLAGS="-I$CONDA_PREFIX/include"
  # export CFLAGS="-Wno-nullability-completeness"
  export LDFLAGS="-L$CONDA_PREFIX/lib -Wl,-rpath -Wl,$CONDA_PREFIX/lib"

  # Possible fix for linking issue:  Need RPATH in libR.so !
  export SHLIB_LDFLAGS="-L$CONDA_PREFIX/lib -Wl,-rpath -Wl,$CONDA_PREFIX/lib"

  echo
  echo "COMPILERS:"
  show CC CXX FC
  echo
  echo "COMPILER SETTINGS:"
  show CPPFLAGS CFLAGS LDFLAGS SHLIB_LDFLAGS
  echo

  echo "CONFIGURE ARGUMENTS:"
  A=(  --prefix=$CONDA_PREFIX
       --enable-R-shlib
       --disable-java
       --without-readline
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

date-secs()
{
  date '+%Y-%m-%d %H:%M:%S'
}

do-command()
{
  local LABEL=$1
  shift
  local CMD=( ${*} )
  {
    echo DO: $(date-secs) $LABEL START:
    echo LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
    if ! ${CMD[@]} 2>&1
    then
      echo DO: $(date-secs) $LABEL FAILED
      exit 1
    fi
    echo DO: $(date-secs) $LABEL STOP.
  } | tee $RECIPE_DIR/build-$LABEL.log
}

# Configure it!
do-command configure do-configure

# Make it!
echo   LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib
do-command make make

# Install it!
do-command install make install

# Test it!
{
  echo "TEST R START: $( date '+%Y-%m-%d %H:%M:%S' )"
  $CONDA_PREFIX/bin/R --version
  $CONDA_PREFIX/bin/R -e 'cat("R-TEST:", 42, "\n")'
  echo "TEST R STOP:  $( date '+%Y-%m-%d %H:%M:%S' )"
} 2>&1 | tee $RECIPE_DIR/build-test.log

echo
echo "BUILD.SH STOP $( date '+%Y-%m-%d %H:%M:%S' )"
echo
