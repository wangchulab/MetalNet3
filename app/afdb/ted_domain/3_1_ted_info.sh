# input
afdb_anno="../collect_annotation/afdb_anno/data/entryId-repId-pfamId-tedId-annoLevel-sp.tsv"
ted_anno_ids="../collect_annotation/ted_domain/data/tedId.tsv"
pred_rep_domain_file="./tmp/pred_rep_domain.tsv"
pred_ted="./tmp/entryId-tedIds-posis.tsv"
# output
ted_consitency="./data/tedId-numPro-numPredPro-numAnnoPro-isAnno.tsv"


awk -F'\t' '
    {
        print $1"\t"$4
    }
' $pred_rep_domain_file | sort -u |\
awk -F'\t' '
    NR==FNR {
        if ($5 != "") {
            anno_pro_ids[$1]
        }
        next
    }

    FILENAME==ARGV[2] {
        anno_ted_ids[$1]
        next
    }

    FILENAME==ARGV[3] {
        ted_id_to_rep_id[$3] = $4
        next
    }

    FILENAME==ARGV[4] {
        delete tmp_rep_ids
        delete arr

        split($2, arr, ",")
        for (i in arr) {
            rep_id = ted_id_to_rep_id[arr[i]]
            tmp_rep_ids[rep_id]
        }

        for (i in tmp_rep_ids) {
            rep_id_to_pred_num[i] ++
        }
        next
    }

    FILENAME==ARGV[5] {
        rep_id_to_total_num[$2]++
        if ($1 in anno_pro_ids) rep_id_to_anno_num[$2]++
        next
    }

    END {
        for (rep_id in rep_id_to_total_num) {
            total_num = rep_id_to_total_num[rep_id]
            anno_num = rep_id in rep_id_to_anno_num ? rep_id_to_anno_num[rep_id] : 0
            pred_num = rep_id_to_pred_num[rep_id]
            is_anno = rep_id in anno_ted_ids ? 1 : 0
            print rep_id"\t"total_num"\t"pred_num"\t"anno_num"\t"is_anno
        }
    }
' $afdb_anno $ted_anno_ids $pred_rep_domain_file $pred_ted - > $ted_consitency