#!/bin/zsh
set -eu

# HUMAN BUILD ZSH
# Interactive wrapper for build.sh
# Does not build an Anaconda package
# Just tries to build R in the current Anaconda environment

if (( ${#*} != 2 )) {
  print "Provide R_SVN WORK"
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

set -x
cd $WORK
cd $BASE
$THIS/build.sh
