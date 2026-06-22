# input
fasta_file="./tmp/metal_chains.fasta"
# output
pred_file="./data/pred.tsv"

source ~/mamba.rc
mamba activate metalnet-seq
project_dir=`realpath ../../../`
scripts_file=$project_dir/model/src/predict.py

preset=metal
model_path=$project_dir/model/train/models/$preset/preset
plm_dir=$project_dir/data/models
toks_per_batch=16384
batch_size=16384
device=cuda:0

python $scripts_file \
    preset=$preset \
    model_path=$model_path \
    plm_dir=$plm_dir \
    device=$device \
    toks_per_batch=$toks_per_batch \
    input_fasta=$fasta_file \
    output_pred=$pred_file \
    device=$device \
    batch_size=$batch_size