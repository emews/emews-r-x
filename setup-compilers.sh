
# SETUP COMPILERS
# source this to set up compilers
# Used by build.sh
# Can also be used interactively

export CC=$(  which clang    )
export CXX=$( which clang++  )
export FC=$(  which gfortran )

# Do not want GNU on Mac:
# export CC=$CONDA_PREFIX/bin/gcc
# export CXX=$CONDA_PREFIX/bin/g++

export FC=$CONDA_PREFIX/bin/gfortran
export CPPFLAGS="-I$CONDA_PREFIX/include -I$CONDA_PREFIX/include/readline"
# export CFLAGS="-Wno-nullability-completeness"
export CFLAGS="$CPPFLAGS"
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
