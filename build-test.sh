#!/bin/bash
set -eu

# BUILD TEST SH
# Quick tests to run after build.sh
# Issued by meta.yaml

say()
{
  echo "build-test.sh:" ${*}
}

if (( ${CONFIG_ONLY:-0} ))
then
  echo "build-test.sh: configure-only: not running tests."
  exit
fi

say "test commands:"

set -x
which R Rscript
R -e 'cat("R-SUCCESS:", 42, "\n")'
