# input
aligned_result="./tmp/409_aligned_result.tsv"
afdb_info="../../../../../_database/afdb_clusters/5-allmembers-repId-entryId-cluFlag-taxId.tsv"
# output
result="./tmp/409_entryId-taxId.tsv"


awk '
    NR==FNR && FNR > 1 {
        ids[$1];
        next
    }

    $2 in ids {
        print $2"\t"$4
    }
' $aligned_result $afdb_info > $result