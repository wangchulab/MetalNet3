# input
pred_ted_domain="./tmp/entryId-tedIds-posis.tsv"
pred_target_domains="./tmp/target_domain.tsv"
afdb_ted_domains="../collect_annotation/ted_domain/tmp/redundantId-entryId-repId-boundaries.tsv"
# output
pred_rep_ted_domains="./tmp/pred_rep_domain.tsv"


awk -F'\t' '
    NR==FNR {
        split($2, arr, ",")
        for (i in arr) {
            pred_ted_ids[arr[i]]
        }
        next
    }

    FILENAME==ARGV[2] {
        if ($3 in pred_ted_ids) {
            pred_rep_ids[$4]
        }
        next
    }

    FILENAME==ARGV[3] {
        if ($3 in pred_rep_ids) {
            if ($1 != "") {
                split($1, arr, "-")
                print arr[2]"\t"$0
            } else {
                split($2, arr, "-")
                print arr[2]"\t"$0
            }
        } 
    }
' $pred_ted_domain $pred_target_domains $afdb_ted_domains > $pred_rep_ted_domains