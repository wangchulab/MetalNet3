# input
high_conf_pred="../predict_afdb/data/pred_ge_3_clique_3.tsv"
afdb_seq_cluster="../_database/afdb_clusters/7-AFDB50-repId_memId.tsv"
# output
high_conf_cluster="./tmp/high_conf_pred_repId-entryId.tsv"

# extract clusters where there is at least one predicted member
awk '
    NR==FNR && NR>1 {
        split($1, arr, "-");
        ids[arr[2]];
        next;
    }
    {
        if ($2 in ids) {
            print $1
        }
    }
' $high_conf_pred $afdb_seq_cluster | sort -u |\
awk '
    NR==FNR {
        ids[$1];
        next
    }
    {
        if ($1 in ids) {
            print $1"\t"$2
        }
    }
' - $afdb_seq_cluster > $high_conf_cluster
