# input
pred="../../data/pred_ge_3_clique_3.tsv"
anno="../../../collect_annotation/afdb_anno/data/entryId-repId-pfamId-tedId-annoLevel-sp.tsv"

awk -F'\t' '
    NR==FNR && FNR>1 {
        split($1, arr, "-");
        ids[arr[2]];
        next
    }
    NR!=FNR && $1 in ids {
        if ($5!="") {
            anno++
            if (index($5, "1")) {
                seq[$2];
                seq_anno++
            }
            if (index($5, "2")) struct_anno++
            if (index($5, "3")) pfam_anno++
            if (index($5, "4")) ted_anno++
        }
    }

    END {
        print anno
        print seq_anno
        print struct_anno
        print ted_anno
        print pfam_anno
    }
' $pred $anno
# 27927308
# 16311554
# 10096783
# 5931519
# 8709939