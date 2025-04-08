
# ENABLE PYTHON
# Source this to enable Python on GitHub Actions

C=/Users/runner/miniconda3/etc/profile.d/conda.sh
echo "sourcing GitHub Actions Miniconda conda.sh:"
ls $C
source $C
echo CONDA_PREFIX=$CONDA_PREFIX
