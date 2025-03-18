#!/bin/bash
set -eu

# INSTALL APPS

# pass CONFIRM=0 via command line for by passing options,
#      default is CONFIRM=1
: ${CONFIRM:=1}

while getopts ":y" OPTION
do
  case $OPTION in
    y) CONFIRM=0
       ;;
    *) # The shell error message was disabled above
       echo "install-apps.sh: unknown option: $*"
       exit 1
       ;;
  esac
done

echo "This will install multiple R packages."
echo

if ! command which R > /dev/null
then
  echo "No R found!"
  exit 1
fi

echo "variables:"
set +u  # These variables may be unset
for var in CC CXX FC
do
  printf "using %-8s = %s\n" $var ${!var}
done
echo
set -u

# On Mac, these should be clang, clang++, gfortran,
#         from the Anaconda installation!
: ${CC:=gcc} ${CPP:=g++} ${FC:=gfortran}

echo "tools:"
for tool in R $CC $CPP $FC
do
  if which $tool 2>&1 > /dev/null
  then
    printf "using %-25s %s\n" "${tool}:" $( which $tool )
  else
    echo "not found: $tool"
  fi
done
echo

if (( ${CONFIRM:-0} == 1 ))
then
  sleep 1
  echo "Press enter to confirm, or Ctrl-C to cancel."
  read _
fi

THIS=$( dirname $0 )

# Do it!
nice R -f $THIS/install-apps.R 2>&1 | tee install-apps.log
