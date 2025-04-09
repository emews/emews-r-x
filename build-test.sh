#!/bin/bash
set -eu

# BUILD TEST SH
# Quick tests to run after build.sh
# Issued by meta.yaml

log()
{
  echo "build-test.sh:" ${*}
}

if (( ${CONFIG_ONLY:-0} ))
then
  log "configure-only: not running tests."
  exit
fi

log "test commands:"

set -x
which R Rscript
R -e 'cat("R-SUCCESS:", 42, "\n")'
