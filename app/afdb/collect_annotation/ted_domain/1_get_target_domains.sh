# input
site_anno_file="../mbp_site_anno/data/entryId-seqNum-resi-metalResi.tsv"
ted_domain_file="./tmp/redundantId-entryId-repId-boundaries.tsv"
# output
target_domain_file="./tmp/target_domain.tsv"

awk -F'\t' '
    NR==FNR {
        ids[$1];
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
' $site_anno_file $ted_domain_file > $target_domain_file