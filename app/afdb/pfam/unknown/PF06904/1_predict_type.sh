# input
pfam_pred="../../tmp/entryId-pfamIds-posis.tsv"
fasta_file="../../../predict_afdb/tmp/pred_ge_3_clique_3.fasta"
pred_file="../../../predict_afdb/data/pred_ge_3_clique_3.tsv"
# output
output_fasta_file="./tmp/PF06904.fasta"
output_file="./tmp/PF06904_pred.tsv"

awk -F'\t' ' NR==FNR && index($2, "PF06904") { print "AFDB:AF-"$1"-F1"}' $pfam_pred | seqkit grep -f - $fasta_file > $output_fasta_file

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
    input_fasta=$output_fasta_file \
    output_pred=${output_fasta_file}.${preset}
done

python $project_dir/model/src/merge.py \
    --p_path $pred_file \
    --tp_path ${output_fasta_file}.${presets[0]} \
    --gtp_path ${output_fasta_file}.${presets[1]} \
    --output_file $output_file
