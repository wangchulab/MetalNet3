# input
afdb_anno_file="../collect_annotation/afdb_anno/data/entryId-repId-pfamId-tedId-annoLevel-sp.tsv"
seq_cluster_anno_file="../collect_annotation/mbp_pro_anno/data/mbp_repId-annoLevel.tsv"
aligned_result="./data/pred_cluster_aligned_result.tsv"
# output
cluster_info_file="./data/repId-numPro-numPredPro-numResi-numPredResi-numAnnoPro-isAnno.tsv"

awk -F'\t' '
    NR==FNR && FNR>1 {
        numPredResi[$6] += split($5, arr, "1") - 1
        numResi[$6] += split($5, arr, ",")
        numPro[$6]++
        if (gsub("1", "", $5) != 0) numPredPro[$6] += 1
        next
    } 
    
    NR!=FNR {
        if ($2 in numPro && $5 != "") {
            numAnnoPro[$2] ++
        }
        next
    }
    
    END {
        for (key in numPro) {
            num_anno_pro = key in numAnnoPro ? numAnnoPro[key] : 0
            print key"\t"numPro[key]"\t"numPredPro[key]"\t"numResi[key]"\t"numPredResi[key]"\t"num_anno_pro
        }
    }
' $aligned_result $afdb_anno_file |\
awk -F'\t' '
    NR==FNR {
        if ($2 == 1) {
            anno_ids[$1];
        }
        next
    }
    {
        if ($1 in anno_ids) {
            print $0"\t"1
        } else {
            print $0"\t"0
        }
    }
' $seq_cluster_anno_file - > $cluster_info_file


# total
wc -l $cluster_info_file # 7415834
awk '{sum += $2} END {print sum}' $cluster_info_file # 46085447

# num of singletons
awk '$2 == 1' $cluster_info_file | wc -l # 4191128

# num of clusters (or members) where all members have the same prediction
awk '$4 == $5' $cluster_info_file | wc -l # 6142107
awk '{if ($4 == $5) print $2}' $cluster_info_file | awk '{sum += $1} END {print sum}'  # 19253237

# num of clusters (or members) where all pred members have the same prediction
awk '($4 / $2) == ($5 / $3)' $cluster_info_file | wc -l # 6643353
awk '{if (($4 / $2) == ($5 / $3)) print $2}' $cluster_info_file | awk '{sum += $1} END {print sum}' # 28801198

# num of clusters (or members in the cluster) that have annotated proteins
awk '$6 != 0' $cluster_info_file | wc -l # 4178161
awk '{if ($6 != 0) print $2}' $cluster_info_file | awk '{sum += $1} END {print sum}' # 35951734