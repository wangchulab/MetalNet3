# input
fasta_file="./tmp/150_idp_mbp.fasta"
pred_file="../../data/pred_ge_3_clique_3.tsv"
# output
output_file="./tmp/150_idp_mbp_pred.tsv"

source ~/mamba.rc
mamba activate metalnet-seq
project_dir="../../../../../"

presets=(metal_type metal_group_type)
for preset in ${presets[@]}
do
python $project_dir/model/src/predict.py \
    preset=$preset \
    model_path=$project_dir/model/train/models/$preset/preset \
    plm_dir=$project_dir/data/models \
    input_fasta=$fasta_file \
    output_pred=${fasta_file}.${preset}
done

python $project_dir/model/src/merge.py \
    --p_path $pred_file \
    --tp_path ${fasta_file}.${presets[0]} \
    --gtp_path ${fasta_file}.${presets[1]} \
    --output_file $output_file

rm ${fasta_file}.${presets[0]} ${fasta_file}.${presets[1]}