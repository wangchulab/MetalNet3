# input
fasta_file="./tmp/pred_homomer.fasta"
pred_file="./tmp/pred_homomer.tsv"
# ouput
output_file="./tmp/pred_homomer_merged.tsv"


source ~/mamba.rc
mamba activate metalnet-seq

project_dir="../../../"
device=cuda:1
toks_per_batch=2048
batch_size=2048

presets=(metal_type metal_group_type)
for preset in ${presets[@]}
do
python $project_dir/model/src/predict.py \
    preset=$preset \
    model_path=$project_dir/model/train/models/$preset/preset \
    plm_dir=$project_dir/data/models \
    toks_per_batch=$toks_per_batch \
    batch_size=$batch_size \
    device=$device \
    input_fasta=$fasta_file \
    output_pred=$fasta_file.$preset
done

python $project_dir/model/src/merge.py \
    --p_path $pred_file \
    --tp_path $fasta_file.${presets[0]} \
    --gtp_path $fasta_file.${presets[1]} \
    --output_file $output_file