# input 
afdb_human_file="../../_database/afdb_clusters/3-sapId_sapGO_repId_cluFlag_LCAtaxId.tsv"
high_conf_pred_file="../../predict_afdb/data/pred_ge_3_clique_3.tsv"
unknown_seq_cluster_file="../../seq_cluster/unknown/data/rep_ids.tsv"
anno_file="../../collect_annotation/afdb_anno/data/entryId-repId-pfamId-tedId-annoLevel-sp.tsv"
# output
filtered_human_file="./tmp/filtered_entryId-repId.tsv"

awk -F'\t' '
    NR==FNR {human_ids[$1]; next} 
    FILENAME==ARGV[2] && FNR>1 {split($1, arr, "-"); high_conf_ids[arr[2]]; next}
    FILENAME==ARGV[3] {cluster_rep_ids[$1]; next}
    {
        if ($2 in cluster_rep_ids && $1 in human_ids && $1 in high_conf_ids && $5 == "" && $6 == 1) {
            print $1"\t"$2
        }
    }
' $afdb_human_file $high_conf_pred_file $unknown_seq_cluster_file $anno_file > $filtered_human_file