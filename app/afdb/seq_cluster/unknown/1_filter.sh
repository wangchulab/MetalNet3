# input
cluster_info_file="../data/repId-numPro-numPredPro-numResi-numPredResi-numAnnoPro-isAnno.tsv"
# output
no_anno_conserved_cluster="./data/rep_ids.tsv"

awk '
{
    if ($6 == 0 && $2 >= 10 && ($3 / $2) >= 0.7) {
        print $1
    }
}
' $cluster_info_file > $no_anno_conserved_cluster