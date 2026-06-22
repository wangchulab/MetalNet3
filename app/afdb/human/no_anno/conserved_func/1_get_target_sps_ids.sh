# input
targets="./data/target_species.tsv"
afdb="../../../_database/afdb_clusters/5-allmembers-repId-entryId-cluFlag-taxId.tsv"
afdb50="../../../_database/afdb_clusters/7-AFDB50-repId_memId.tsv"
# output
targets_ids="./tmp/entryId-repId-taxId.tsv"

awk -F'\t' '
    NR==FNR {
        ids[$4];
        next
    }

    FILENAME==ARGV[2] {
        if ($4 in ids) {
            seq_id_to_tax_id[$2] = $4
        }
        next
    }

    FILENAME==ARGV[3] {
        if ($2 in seq_id_to_tax_id) {
            seq_id_to_rep_id[$2] = $1
        }
        next
    }

    END {
        for (seq_id in seq_id_to_tax_id) {
            tax_id = seq_id_to_tax_id[seq_id]
            rep_id = seq_id_to_rep_id[seq_id]
            print seq_id"\t"rep_id"\t"tax_id
        }
    }
' $targets $afdb $afdb50 > $targets_ids