# input
pfam_domain="./data/entryId-pfamId.tsv"
# output
anno_pfam_domains="./data/pfamId.tsv"

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

get_domains $pfam_domain > $anno_pfam_domains