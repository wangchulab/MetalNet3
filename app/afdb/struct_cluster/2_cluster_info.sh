# input
afdb_anno="../collect_annotation/afdb_anno/data/entryId-repId-pfamId-tedId-annoLevel-sp.tsv"
seq_cluster_info="../seq_cluster/data/repId-numPro-numPredPro-numResi-numPredResi-numAnnoPro-isAnno.tsv"
afdb_seq_cluster="../_database/afdb_clusters/7-AFDB50-repId_memId.tsv"
struct_cluster_file="./tmp/repId-entryId.tsv"
# output
cluster_info_file="./data/repId-numSeqRep-numPredSeqRep-numAnnoSeqRep-numPro-numPredPro-numAnnoPro.tsv"

awk -F'\t' '
    NR==FNR {
        seq_to_struct[$2] = $1
        next
    }
    FILENAME==ARGV[2] && $1 in seq_to_struct {
        seq_id_to_total_num[$1]++
        next
    }

    FILENAME==ARGV[3] && $1 in seq_to_struct {
        seq_id_to_pred_num[$1] += $3
        anno_seq_rep[$1] = $7
        next
    }

    FILENAME==ARGV[4] && $2 in seq_to_struct {
        if ($5 != "") {
            seq_id_to_anno_num[$2] ++
        }
        next
    }

    END {
        for (seq_id in seq_to_struct) {
            struct_id = seq_to_struct[seq_id]
            total_num = seq_id_to_total_num[seq_id]
            total_pred_num = seq_id in seq_id_to_pred_num ? seq_id_to_pred_num[seq_id] : 0
            total_anno_num = seq_id in seq_id_to_anno_num ? seq_id_to_anno_num[seq_id] : 0
            is_seq_anno = anno_seq_rep[seq_id]
            print struct_id"\t"seq_id"\t"total_num"\t"total_pred_num"\t"total_anno_num"\t"is_seq_anno
        }
    }
' $struct_cluster_file $afdb_seq_cluster $seq_cluster_info $afdb_anno |\
awk -F'\t' '
    {
        struct_id = $1
        total_num[struct_id] += $3
        total_pred_num[struct_id] += $4
        total_anno_num[struct_id] += $5
        seq_rep_num[struct_id] ++
        is_pred_rep = $4 > 0 ? 1 : 0
        seq_pred_rep_num[struct_id] += is_pred_rep
        seq_anno_rep_num[struct_id] += $6
    }

    END {
        for (struct_id in total_num) {
            print struct_id"\t"seq_rep_num[struct_id]"\t"seq_pred_rep_num[struct_id]"\t"seq_anno_rep_num[struct_id]"\t"total_num[struct_id]"\t"total_pred_num[struct_id]"\t"total_anno_num[struct_id]
        }
    }
' - > $cluster_info_file