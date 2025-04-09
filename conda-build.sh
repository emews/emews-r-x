#!/bin/zsh
set -eu

# CONDA BUILD ZSH
# Generic wrapper around `conda build'
# Runs `conda build'
# A LOG is produced in conda-build.log
# You can only run 1 job concurrently
#     because of the log and
#     because of meta.yaml
# The R source must have already been put in the location
#     specified in meta.yaml:source:path:

# Hard-coded for now- on other systems, we use community R packages
# Also set in meta.yaml
export PLATFORM=${PLATFORM:-osx-arm64}

help()
{
  cat <<END

Options:
   -S Settings:  Just reports startup settings and exits
   -C Configure: Just runs configure, not make
END
}

C="" S=""
zparseopts -D -E -F h=HELP C=C S=S

if (( ${#HELP} )) {
  help
  exit
}

if (( ${#C} )) export CONFIG_ONLY=1

# Get this directory
THIS=${0:A:h}

if (( ${#*} != 1 )) {
  print "Provide R SVN location!"
  return 1
}
# This is substituted into meta.yaml:
export R_SVN=$1

if [[ ! -d $R_SVN ]] {
  print "does not exist: R_SVN=$R_SVN"
  return 1
}

if ! grep -q "R_HOME" $R_SVN/Makefile.in
then
  print "wrong directory: R_SVN=$R_SVN"
  return 1
fi

if [[ $PLATFORM =~ osx-* ]] {
  if [[ $(uname) != "Darwin" ]] {
    print "platform mismatch!"
    print "uname: $(uname)"
    print "PLATFORM=$PLATFORM"
    return 1
  }
}

DATE_FMT_S="%D{%Y-%m-%d} %D{%H:%M:%S}"
log()
# General-purpose log line
{
  print ${(%)DATE_FMT_S} "conda-build.sh:" ${*}
}

if (( ${GITHUB_ACTIONS:-0} ))
then
  source ./enable-python.sh
fi

# Look up executable:
PYTHON_EXE=( =python )
# Get its directory:
PYTHON_BIN=${PYTHON_EXE:h}

# print LISTING
# print PYTHON_EXE $PYTHON_EXE $PYTHON_BIN
# ls $PYTHON_BIN
# conda list

# Check that the conda-build tool in use is in the
#       selected Python installation
if ! which conda-build >& /dev/null
then
  log "could not find tool: conda-build"
  log "                     run ./setup-conda.sh"
  return 1
fi
# Look up executable:
CONDA_BUILD_TOOL=( =conda-build )
# Get its directory:
TOOLDIR=${CONDA_BUILD_TOOL:h}
if [[ ${TOOLDIR} != ${PYTHON_BIN} ]] {
  log "conda-build is not in your python directory!"
  log "            this is probably wrong!"
  log "            run ./setup-conda.sh"
  return 1
}

# Backup the old log
LOG=conda-build.log
log "LOG: $LOG"
if [[ -f $LOG ]] {
  mv -v $LOG $LOG.bak
  print
}

if (( ${#S} )) {
  log "settings-only: exit." | tee $LOG
  return
}

{
  log "CONDA BUILD: START:"
  print
  (
    log "using python: " $( which python )
    log "using conda:  " $( which conda  )
    log "PLATFORM:     " $PLATFORM
    print
    conda env list
    print

    BUILD_ARGS=(
      -c conda-forge
      --dirty
      --keep-old-work
      # --no-remove-work-dir
      --prefix-length 128
      .
    )

    set -x
    # This purge-all is extremely important:
    conda build purge-all

    # Build the package!
    conda build $BUILD_ARGS
  )
  log "CONDA BUILD: STOP: ${(%)DATE_FMT_S}"
} |& tee $LOG
print
log "SUCCESS."
print

if (( ${CONFIG_ONLY:-0} )) {
  log "configure-only: done."
  return
}

# Look for success from meta.yaml:test:commands:
# Output
if ! grep -q "R-SUCCESS: 42" $LOG
then
  log "FATAL: Did not find R-SUCCESS in $LOG"
  exit 1
fi

# Find the "upload" text for the PKG in the LOG,
#      this will give us the PKG file name
log "looking for upload line in $LOG ..."
UPLOAD=( $( grep -A 1 "anaconda upload" $LOG ) )
PKG=${UPLOAD[-1]}

checksum()
{
  # Use redirection to suppress filename in md5 output
  local PKG=$1
  if [[ $PLATFORM =~ osx-* ]] {
    md5 -r < $PKG
  } else {
    md5sum < $PKG
  }
}

# Print metadata about the PKG
(
  print
  zmodload zsh/mathfunc zsh/stat
  print PKG=$PKG
  zstat -H A -F "%Y-%m-%d %H:%M" $PKG
  log  "TIME: ${A[mtime]} ${A[size]}"
  printf -v T "SIZE: %.1f MB" $(( float(${A[size]}) / (1024*1024) ))
  log $T
  log "HASH:" $( checksum $PKG )
) | tee -a $LOG

# This is mostly for GitHub Action step checking
echo "CONDA-BUILD: SUCCESS" > $LOG
