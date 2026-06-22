# input
tax_ids_file="./data/tax_ids.tsv"
high_conf_pred="../../../../predict_afdb/data/pred_ge_3_clique_3.tsv"
afdb_all_file="../../../../_database/afdb_clusters/5-allmembers-repId-entryId-cluFlag-taxId.tsv"
afdb50="../../../../_database/afdb_clusters/7-AFDB50-repId_memId.tsv"
afdb_cluster="../../../../_database/afdb_clusters/1-AFDBClusters-entryId_repId_taxId.tsv"
unknown_seq="../../data/rep_ids.tsv"
unknown_struct="../../../../struct_cluster/unknown/data/rep_ids.tsv"
dark_struct_cluster="../../../../_database/afdb_clusters/2-repId_isDark_nMem_repLen_avgLen_repPlddt_avgPlddt_LCAtaxId.tsv"
# output
no_anno_file="./data/entryId-seqRepId-structRepId-unknownLevel.tsv"

awk -F'\t' '
    NR==FNR {
        tax_ids[$1]
        next
    }

    FILENAME==ARGV[2] {
        if ($4 in tax_ids) {
            ids[$2]
        }
        next
    }

    FILENAME==ARGV[3] {
        if ($2 in ids) {
            id_to_seq_rep_id[$2] = $1
            seq_rep_ids[$1]
        }
        next
    }

    FILENAME==ARGV[4] {
        if ($1 in seq_rep_ids) {
            seq_rep_id_to_struct_rep_id[$1] = $2
        }
        next
    }

    FILENAME==ARGV[5] && FNR > 1 {
        split($1, arr, "-")
        if (arr[2] in ids) {
            high_conf_ids[arr[2]]
        }
        next
    }

    END {
        for (id in ids) {
            if (id in high_conf_ids) {
                seq_rep_id = id_to_seq_rep_id[id]
                struct_rep_id = (seq_rep_id in seq_rep_id_to_struct_rep_id) ? seq_rep_id_to_struct_rep_id[seq_rep_id] : ""
                print id"\t"seq_rep_id"\t"struct_rep_id
            }
        }
    }
' $tax_ids_file $afdb_all_file $afdb50 $afdb_cluster $high_conf_pred |\
awk -F '\t' '
    NR==FNR {
        seq_ids[$1]
        next
    }

    FILENAME==ARGV[2] {
        struct_ids[$1]
        next
    }

    FILENAME==ARGV[3] {
        if ($2) {
            dark_struct_id[$1]
        }
        next
    }

    FILENAME==ARGV[4] {
        if ($3 in dark_struct_id) {
            in_seq = $2 in seq_ids
            in_struct = $3 in struct_ids
            if (in_seq || in_struct) {
                if (in_seq && in_struct) {
                    unknown_level = "1,2"
                } else if (in_seq) {
                    unknown_level = "1"
                } else {
                    unknown_level = "2"
                }
                print $0"\t"unknown_level
            }
        }
    }
' $unknown_seq $unknown_struct $dark_struct_cluster - > $no_anno_file