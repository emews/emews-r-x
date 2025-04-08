
# ENABLE PYTHON
# Source this to enable Python on GitHub Actions

C_SH=/Users/runner/miniconda3/etc/profile.d/conda.sh
echo "sourcing GitHub Actions Miniconda conda.sh:"
ls $C_SH
source $C_SH
echo CONDA_PREFIX=$CONDA_PREFIX
echo
