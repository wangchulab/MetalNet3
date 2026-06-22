# input
fasta_file="./tmp/high_conf_pred_cluster.fasta"
cluster_file="./tmp/high_conf_pred_repId-entryId.tsv"
pred_file="../predict_afdb/data/pred_ge_3_clique_3.tsv"
# output
result_file="./data/pred_cluster_aligned_result.tsv"

source ~/mamba.rc
mamba activate metalnet-helper

# 1 day if parallel on 400 cpu cores
python "./scripts/align_pred.py" \
    --fasta_file $fasta_file \
    --cluster_file $cluster_file \
    --pred_file $pred_file \
    --result_file $result_file