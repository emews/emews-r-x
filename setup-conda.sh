#!/bin/bash
set -eu

# SETUP CONDA
# Install Anaconda build tools

echo "setting up Anaconda build tools in:"
which conda
echo

conda env list

PKGS=(
  # Basic tools:
  conda-build
  anaconda-client
  # Needed for R:
  svn
)

set -x
conda install --yes ${PKGS[@]}

# Suppress this behavior from Conda on "conda build" errors:
# Would you like conda to send this report to the core maintainers? [y/N]:
# No report sent. To permanently opt-out, use:
conda config --set report_errors false
