#!/bin/sh

# DEACTIVATE SH
# See activate.sh

echo "emews-r-x deactivate.sh: unsetting R_LIBS_USER"

if [[ ! -z ${R_LIBS_USER_BACKUP+x} ]]; then
  export R_LIBS_USER="$R_LIBS_USER_BACKUP"
  unset R_LIBS_USER_BACKUP
else
  unset R_LIBS_USER
fi
