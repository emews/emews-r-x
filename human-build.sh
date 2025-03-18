#!/bin/zsh
set -eu

# HUMAN BUILD ZSH
# Interactive wrapper for build.sh
# Does not build an Anaconda package
# Just tries to build R in the current Anaconda environment

zparseopts -D -E c=CLEAN
if (( ${#*} != 2 )) {
  print -- "Provide [-c] R_SVN WORK: got: ${*}"
  return 1
}
R_SVN=$1
WORK=$2

if [[ ! -d $R_SVN ]] {
  print "does not exist: R_SVN=$R_SVN"
  return 1
}

if ! grep -q "R_HOME" $R_SVN/Makefile.in
then
  print "wrong directory: R_SVN=$R_SVN"
  return 1
fi

print "WORK=$WORK"
mkdir -pv $WORK

cp -ru $R_SVN $WORK

THIS=${0:h:A}
BASE=$( basename $R_SVN )

cd $WORK
cd $BASE

if (( ${#CLEAN} )) && [[ -f Makefile ]] make clean

$THIS/build.sh
