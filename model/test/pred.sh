#!/usr/bin/env bash

# Predict metal-binding sites for citx.fasta using the `metal` preset (SVM + ankh-base).

#source ~/mamba.rc
#mamba activate metalnet-seq

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_dir="$(cd "$SCRIPT_DIR/../.." && pwd)"

scripts_file=$project_dir/model/src/predict.py

preset=metal
model_path=$project_dir/model/train/models/$preset/preset
plm_dir=$project_dir/data/models

python $scripts_file \
    preset=$preset \
    model_path=$model_path \
    plm_dir=$plm_dir \
    input_fasta=$SCRIPT_DIR/citx.fasta \
    output_pred=$SCRIPT_DIR/citx_pred.tsv \
    device=cuda:0
