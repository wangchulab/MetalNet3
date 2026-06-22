source ~/mamba.rc
mamba activate metalnet-seq
project_dir=`realpath "../../../"`
scripts_file=$project_dir/model/src/predict.py

preset=metal
model_path=$project_dir/model/train/models/$preset/preset
plm_dir=$project_dir/data/models
toks_per_batch=16384
batch_size=16384

files=$1 # afdb ~0.2B seqs, cost about ~4 days with 16 nvidia-l40 gpus
device=$2

python $scripts_file \
    preset=$preset \
    model_path=$model_path \
    plm_dir=$plm_dir \
    input_files=$files \
    device=$device \
    toks_per_batch=$toks_per_batch \
    batch_size=$batch_size