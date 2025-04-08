#!/bin/bash
set -eu
set -o pipefail

# BUILD SH

# Remember to merge output streams into logs to try to prevent
#       buffering problems with conda build

# Environment notes:
# Generally, environment variables are not inherited into here.

# CONDA_PREFIX, PREFIX, RECIPE_DIR are provided by Conda

# You can run this interactively, in which case
# CONDA_PREFIX should be set by your Anaconda installation,
# and this script sets RECIPE_DIR.  PREFIX will be unset.

TIMESTAMP=$( date '+%Y-%m-%d %H:%M:%S' )

echo
echo "BUILD.SH START $TIMESTAMP"
echo

show()
# Report shell value, aligned
{
  local V
  for V in ${*}
  do
    printf "%-13s %s\n" ${V}: ${!V:-unset}
  done
}

if [[ ${RECIPE_DIR:-} == "" ]]
then
  RECIPE_DIR=$( cd $( dirname $0 ) ; /bin/pwd -P )
  echo "Interactive mode: RECIPE_DIR=$RECIPE_DIR"
fi

{
  echo "python:" $( which python )
  show TIMESTAMP
  show PWD
  show RECIPE_DIR
  show SRC_DIR
  show PREFIX
} | tee $RECIPE_DIR/build-metadata.log

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

  source $RECIPE_DIR/setup-compilers.sh

  echo "CONFIGURE ARGUMENTS:"
  A=(  --prefix=$CONDA_PREFIX
       --enable-R-shlib
       --disable-java
       # --without-readline
       --without-tcltk
       # --without-cairo
       --without-jpeglib
       --without-libtiff
       --without-ICU
       --with-included-gettext
       # --without-x
       --without-recommended-packages
       # /--without-aqua
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

do-activate-sh()
{
  # Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
  # This will allow them to be run on environment activation.
  for CHANGE in "activate" "deactivate"
  do
    local D=$PREFIX/etc/conda/${CHANGE}.d
    mkdir -pv "$D"
    cp -v "$RECIPE_DIR/${CHANGE}.sh" "$D/${PKG_NAME}_${CHANGE}.sh"
  done
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
    echo
    echo DO: $(date-secs) $LABEL START:
    show PWD LD_LIBRARY_PATH

    if ! ${CMD[@]} 2>&1
    then
      echo DO: $(date-secs) $LABEL FAILED
      exit 1
    fi
    echo DO: $(date-secs) $LABEL STOP.
  } | tee $RECIPE_DIR/build-$LABEL.log
}

# Post-build stuff!
do-command activate-sh do-activate-sh

# Configure it!
do-command configure do-configure

# Make it!
echo   LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}
export LD_LIBRARY_PATH=$CONDA_PREFIX/lib
echo PWD=$PWD
do-command make make -j 4

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
