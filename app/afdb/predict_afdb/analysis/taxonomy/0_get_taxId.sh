# input
afdb_tax_file="../../../_database/afdb_clusters/5-allmembers-repId-entryId-cluFlag-taxId.tsv"
afdb50="../../../_database/afdb_clusters/7-AFDB50-repId_memId.tsv"
tax_id_merged="../../../_database/taxonomy/merged.dmp"
metaldb="../../data/pred_ge_3_clique_3.tsv"
# output: emtpy tax id in afdb_tax_file viewed as  -1; tax_ids updated by merged.dmp
afdb50_tax="./tmp/afdb50_repId-entryId-taxId.tsv"
metaldb_tax="./tmp/metaldb_repId-entryId-taxId.tsv"

awk -F'\t' '
    NR==FNR {
        old2new[$1] = $3
        next
    }
    FILENAME==ARGV[2] {
        id = $4 != "" ? $4 : -1
        seq_id_to_tax_id[$2] = id in old2new ? old2new[id] : id
        next
    }
    FILENAME==ARGV[3] {
        print $1"\t"$2"\t"seq_id_to_tax_id[$2]
    }
' $tax_id_merged $afdb_tax_file $afdb50 > $afdb50_tax

awk -F'\t' '
    NR==FNR && FNR>1 {
        split($1, arr, "-")
        ids[arr[2]]
        next
    }

    $2 in ids {
        print $0
    }
' $metaldb $afdb50_tax > $metaldb_tax