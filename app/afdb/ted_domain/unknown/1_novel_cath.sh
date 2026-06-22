# input
novel_ted="../tmp/repId-hasCATH-isNovel-isSymm.tsv"
pred_ted_cath="../analysis/cath_mbp_domain/tmp/pred_repId-cath.tsv"
anno_ted_cath="../analysis/cath_mbp_domain/tmp/anno_repId-cath.tsv"
pdb_cath_orig="../../_database/cath/cath-domain-list.txt"
# output
novel_ted_cath="./tmp/tedId-cath.tsv"
pdb_cat="./tmp/pdb-cat.tsv"

awk -F'\t' '
    NR==FNR {
        novel_rep_ids[$1];
        next;
    }

    FILENAME==ARGV[2] {
        split($2, arr, ".")
        cat_label = arr[1]"."arr[2]"."arr[3]
        anno_cat[cat_label]
        next
    }

    FILENAME==ARGV[3] {
        if ($1 in novel_rep_ids) {
            split($2, arr, ".")
            cat_label = arr[1]"."arr[2]"."arr[3]
            if (!(cat_label in anno_cat)) {
                print $0
            }
        }
    }
' $novel_ted $anno_ted_cath $pred_ted_cath > $novel_ted_cath

awk '
    NR==FNR {
        split($2, arr, ".")
        cat_label = arr[1]"."arr[2]"."arr[3]
        ids[cat_label]
        next
    }

    $0 !~ /^#/ {
        pdb_id = $1
        cat = $2 "." $3 "." $4
        if (cat in ids) {
            print pdb_id"\t"cat
        }
    }
' $novel_ted_cath $pdb_cath_orig > $pdb_cat