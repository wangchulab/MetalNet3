
# Install

## python environments

```bash
mamba create -n metalnet-seq -c pytorch -c nvidia -c rapidsai -c conda-forge \
    pytorch=2.4.1 pytorch-cuda=12.1 \
    cudf=24.08 cuml=24.08 cuda-version=12.1 \
    autogluon==1.1.1 python=3.11

pip install hydra-core==1.3.2 hydra-optuna-sweeper==1.2.0 hydra-joblib-launcher==1.2.0 biopython==1.84
```


# Optional

## python environments

For ESMC encoding in metalnet-seq:
```bash
pip install esm==3.1.1
```

For mbps mining and visualization:
```bash
mamba create -n metalnet-helper -c conda-forge matplotlib==3.10.0 python==3.11

pip install goatools==1.4.12 biopython==1.84 absl-py==2.1.0 pandas==2.2.3 tqdm==4.66.5\
 networkx==3.4.2 seaborn==0.13.2 scikit-learn==1.6.1 matplotlib-venn==1.1.2 pyyaml==6.0.2\
 ete4==4.3.0 foldcomp==0.0.7

mamba install -c bioconda -c conda-forge eggnog-mapper==2.1.13
# install ipykernel packages

```

For protenix prediction:
```bash
mamba create -n protenix python=3.11
pip install protenix==0.7.3
```

## executables

- [seqkit](https://github.com/shenwei356/seqkit): v2.8.0

- [mmseqs](https://github.com/soedinglab/MMseqs2): 6f45232ac8daca14e354ae320a4359056ec524c2

- [clustalo](http://www.clustal.org/omega/): v1.2.4

- [blast](https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/2.14.0/ncbi-blast-2.14.0+-x64-linux.tar.gz): 2.14.0

- [taxonkit](https://github.com/shenwei356/taxonkit): v0.20.0

## ipynb notebook patches:

```bash
PACKAGE_PATH="/path/to/site-packages"

# add arial related font to matplotlib
cp "./asset/*.ttf" -t $PACKAGE_PATH/matplotlib/mpl-data/fonts/ttf/
rm -r "~/.cache/matplotlib/"
```

Add `PROJECT_DIR = "/path/to/metalnet-seq"` in `~/.ipython/profile_default/ipython_config.py` as a global variable for use.