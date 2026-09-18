
# Install (~ 20min)

## python environments

```bash
mamba create -n metalnet-seq -c pytorch -c nvidia -c rapidsai -c conda-forge \
    pytorch=2.4.1 pytorch-cuda=12.1 \
    cudf=24.08 cuml=24.08 cuda-version=12.1 \
    autogluon==1.1.1 python=3.11 "setuptools<70"

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

Add `PROJECT_DIR = "/path/to/MetalNet3"` in `~/.ipython/profile_default/ipython_config.py` as a global variable for use.


# Usage

## Download model parameters (~ 1hour)

### Protein language models (PLMs)

```bash
cd data
python download_models.py
```

This downloads all PLMs from Hugging Face into `data/models/`, which is referenced by `plm_dir` in the configs. If you already have the PLMs installed, you can symlink the `models` folder to their existing location instead of re-downloading.

### Prediction models

Download the pre-trained prediction models from [Google Drive](https://drive.google.com/drive/folders/1rn1FnCUmitY85UwWKD45Z1-Ou7QEnnsv?usp=share_link) and unpack them to `model/train/models/`. Each task folder contains a model directory named `<model>_<plm>` (e.g. `svm_ankh-base`) and a `preset` symlink pointing to it:

```
model/train/models/
├── metal/
│   ├── preset -> ./svm_ankh-base
│   └── svm_ankh-base/
├── metal_group_type/
│   ├── preset -> ./svm_ankh-base
│   └── svm_ankh-base/
└── metal_type/
    ├── preset -> ./nn_esm2-3B
    └── nn_esm2-3B/
```

If the `preset` symlink is missing after unpacking, create it:

```bash
cd model/train/models/metal && ln -s ./svm_ankh-base preset
cd model/train/models/metal_group_type && ln -s ./svm_ankh-base preset
cd model/train/models/metal_type && ln -s ./nn_esm2-3B preset
```

## Predict a sequence (< 1s)

```bash
cd model/test/  #pred.sh
python ../../model/src/predict.py \
    preset=metal \
    model_path=../../model/train/models/metal/preset \
    plm_dir=../../data/models \
    input_fasta=citx.fasta \
    output_pred=citx_pred.tsv \
    device=cuda:0
```
The reference output is `citx_pred_ref.tsv`.

`preset` selects the task and must match `model_path`: `metal` → `model/train/models/metal/preset`, `metal_type` → `model/train/models/metal_type/preset`, `metal_group_type` → `model/train/models/metal_group_type/preset`. The output is a TSV file reporting the predicted site positions and scores.

## Reproduce training

All training-related data are hosted on [Zenodo](https://zenodo.org/records/20687409). To reproduce the full training pipeline, download `data.zip` (code and all data). Use `model/train/cmd.sh` as the entry point and adjust the `plms` list to scan as needed.
