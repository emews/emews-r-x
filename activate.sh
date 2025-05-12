#!/bin/sh

# ACTIVATE SH
# This is installed in Anaconda and run during 'conda activate'
# This fixes the R library path so that the wrong libraries
#      from different compilers do not get automatically
#      found and loaded
# This effect is visible in .libPaths()

echo "emews-r-x activate.sh: setting R_LIBS_USER"

if [[ ! -z ${R_LIBS_USER+x} ]]; then
  export R_LIBS_USER_BACKUP="$R_LIBS_USER"
fi
export R_LIBS_USER="$CONDA_PREFIX/lib/R/library"
