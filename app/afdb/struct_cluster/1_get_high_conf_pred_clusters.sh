# input
high_conf_pred_rep="../seq_cluster/data/repId-numPro-numPredPro-numResi-numPredResi-numAnnoPro-isAnno.tsv"
afdb_struct_cluster="../_database/afdb_clusters/1-AFDBClusters-entryId_repId_taxId.tsv"
# output
high_conf_cluster="./tmp/repId-entryId.tsv"

# extract struct clusters where there is at least one predicted seq cluster
awk -F'\t' '
    NR==FNR {
        seq_rep_ids[$1];
        next
    }
    FILENAME==ARGV[2]{
        seq_to_struct_ids[$1] = $2
        if ($1 in seq_rep_ids) {
            targets[$2]
        }
        next
    }

    END {
        for (i in seq_to_struct_ids) {
            struct_id = seq_to_struct_ids[i]
            if (struct_id in targets) {
                print struct_id"\t"i
            }
        }
    }
' $high_conf_pred_rep $afdb_struct_cluster | sort -u > $high_conf_cluster