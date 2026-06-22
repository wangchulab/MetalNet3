source ~/mamba.rc
mamba activate metalnet-seq
project_dir=`realpath "../../../../"`

scripts_file=$project_dir/model/src/predict.py
models_dir=$project_dir/model/train/models
plm_dir=$project_dir/data/models
test_fasta_file=./data/afdb_10k_runtime_test.fasta

# from comparison result on test dataset
# test env: nvidia L40
suites=(
    "ag esm2-150M 16384"
    "ag esm2-650M 16384"
    "svm prott5-xl 16384"
    "svm esm2-3B 4096"
    "svm ankh-base 16384"
    "svm ankh-large 16384"
)

for s in "${suites[@]}"
do
read -r model plm batch_size <<< "$s"
model_path=$models_dir/metal/${model}_${plm}
python $scripts_file \
    plm_dir=$plm_dir \
    model_path=$model_path \
    device=cuda:0 \
    input_fasta=$test_fasta_file \
    preset=metal \
    plm@preset.plm=$plm \
    model@preset.model=$model \
    preset.proba_cutoff=0 \
    toks_per_batch=16384 \
    batch_size=$batch_size
done
