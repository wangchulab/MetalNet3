# input
site_pred_file="../predict_afdb/data/pred_ge_3_clique_3.tsv"
ted_domain_file="../collect_annotation/ted_domain/tmp/redundantId-entryId-repId-boundaries.tsv"
# output
target_domain_file="./tmp/target_domain.tsv"

awk -F'\t' '
    NR==FNR && FNR > 1 {
        split($1, arr, "-")
        ids[arr[2]];
        next
    }
    {
        if ($1 != "") {
            split($1, arr, "-")
            if (arr[2] in ids) {
                print arr[2]"\t"$0
            }
        } else {
            split($2, arr, "-")
            if (arr[2] in ids) {
                print arr[2]"\t"$0
            }
        }
    }
' $site_pred_file $ted_domain_file > $target_domain_file