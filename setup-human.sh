#!/bin/zsh
set -eu

zparseopts -D -E s=S

SOLVER=()
if (( ${#S} )) SOLVER=( --solver classic )

echo "setting up Anaconda R compiler tools in:"
which conda
echo

conda env list

# Keep in sync with meta.yaml:
PKGS=(
  libcurl
  pcre2
  xz
  gfortran
  # For shell issue:
  ncurses
  zlib

  # For X11:
  # xorg-x11-proto-devel-cos6-x86_64
  xorg-libx11 # xorg-x11-proto-devel
  xorg-xorgproto
  xorg-libxt  # For X11/Intrinsic.h
  libiconv  # For iconv.h
)

set -x
conda install --yes -c conda-forge $SOLVER $PKGS
