# input
cluster_info_file="../data/repId-numSeqRep-numPredSeqRep-numAnnoSeqRep-numPro-numPredPro-numAnnoPro.tsv"
# output
no_anno_cluster="./data/rep_ids.tsv"

awk '
    $7 == 0 && $2 >= 10 && ($3 / $2) >= 0.5 {
        print $1
    }
' $cluster_info_file > $no_anno_cluster
