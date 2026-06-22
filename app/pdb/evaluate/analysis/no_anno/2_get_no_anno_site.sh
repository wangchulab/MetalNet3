# input
new_uni="./tmp/pdbId-entryId.tsv"
pfam_anno_file="../../../../afdb/collect_annotation/pfam/data/entryId-pfamId.tsv"
ted_cluster_file="../../../../afdb/collect_annotation/ted_domain/tmp/redundantId-entryId-repId-boundaries.tsv"
ted_anno_file="../../../../afdb/collect_annotation/ted_domain/data/entryId-tedId.tsv"
# tmp
no_anno_by_pfam="./tmp/no_anno_pfam_entryId-pfamId.tsv"
no_anno_by_ted="./tmp/no_anno_by_entryId-tedRepId.tsv"

awk '
    FNR==1 { fileNo++ }

    fileNo==1 {
        ids[$2];
        next
    }

    fileNo==2 {
        if ($1 in ids) {
            split($2, arr, ",")
            for (i in arr) {
                cur_pfam_ids[arr[i]]
            }
        }
        next
    }

    fileNo==3 {
        split($2, arr, ",")
        for (i in arr) {
            if (arr[i] in cur_pfam_ids) {
                print $1"\t"arr[i]
            }
        }
    }
' $new_uni $pfam_anno_file $pfam_anno_file > $no_anno_by_pfam

awk -F'\t' '
    FNR==1 { fileNo++ }

    fileNo==1 {
        ids[$2];
        next
    }

    fileNo==2 {
        split($2, arr, ",")
        for (i in arr) {
            if ($1 in ids) {
                cur_ted_ids[arr[i]]
            }
            ted_ids[arr[i]]
        }
        next
    }

    fileNo==3 {
        if ($2 in ted_ids) {
            ted_id_to_rep_id[$2] = $3
            if ($2 in cur_ted_ids) {
                cur_ted_rep_ids[$3]
            }
        }
        next
    }

    fileNo==4 {
        split($2, arr, ",")
        for (i in arr) {
            rep_id = ted_id_to_rep_id[arr[i]]
            if (rep_id in cur_ted_rep_ids) {
                print $1"\t"rep_id
            }
        }
    }
' $new_uni $ted_anno_file $ted_cluster_file $ted_anno_file > $no_anno_by_ted