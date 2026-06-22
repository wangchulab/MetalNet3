# input
ted_domain="./data/entryId-tedId.tsv"
afdb_domain_info="./tmp/redundantId-entryId-repId-boundaries.tsv"
# output: ted100 cluster ids
anno_ted_domains="./data/tedId.tsv"

get_domains() {
    awk '
        {
            split($2, arr, ",")
            for (i in arr) {
                ids[arr[i]]
            }
        }

        END {
            for (id in ids) {
                print id
            }
        }
    ' $1
}

get_domains $ted_domain |\
awk -F'\t' '
    NR==FNR {
        ids[$1]
        next;
    }

    $2 in ids {
        print $3
    }
' - $afdb_domain_info | sort -u > $anno_ted_domains