#!/bin/bash
set -eu

# META TEST SH
# Quick tests to run after build phase
# Issued by meta.yaml

log()
{
  echo "meta-test.sh:" ${*}
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
