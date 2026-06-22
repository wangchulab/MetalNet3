# input
ted_cluster_anno="../data/tedId-numPro-numPredPro-numAnnoPro-isAnno.tsv"
ted_cluster_info="../data/repId-hasCATH-isNovel-isSymm.tsv"
# output
potential_ted_cluster_info="./tmp/repId-hasCATH-isNovel-isSymm.tsv"

awk -F '\t' '
    NR==FNR {
        if ($4 == 0) {
            ids[$1]
        }
        next
    }

    $1 in ids {
        print $0
    }
' $ted_cluster_anno $ted_cluster_info > $potential_ted_cluster_info

awk '$3 == 1' $potential_ted_cluster_info | wc -l # 806
awk '$4 == 1' $potential_ted_cluster_info | wc -l # 440