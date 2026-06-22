# input
membrane_anno="../../../../collect_annotation/membrane_pro_anno/data/membrane_repId-annoLevel.tsv"
pred_result="../../../../predict_afdb/data/pred_ge_3_clique_3.tsv"
metal_anno="../../../data/repId-numPro-numPredPro-numResi-numPredResi-numAnnoPro-isAnno.tsv"
target_clusters="../data/clique_2_diverged.tsv"
cluster_fasta="../../../tmp/high_conf_pred_cluster.fasta"

# output
result="./data/repId-cliques-numAnnoPro-isAnno-memAnnoLevel-repLen-repName-avgPLDDT.tsv"

awk 'NR>1 {print "AFDB:AF-"$1"-F1"}' $target_clusters | seqkit grep -f - $cluster_fasta | seqkit fx2tab - -n -l |\
awk -F'\t' '
    NR==FNR && FNR > 1 {
        ids[$1] = $2;
        next
    }

    FILENAME==ARGV[2] && $1 in ids {
        id2num_anno_pro[$1] = $6
        id2is_anno[$1] = $7
        next
    }

    FILENAME==ARGV[3] && $1 in ids {
        id2mem_anno_level[$1] = $2
        next
    }

    FILENAME==ARGV[4] {
        split($1, arr, " ")
        split(arr[1], arr1, "-")
        id = arr1[2]
        id2len[id] = $2
        id2name[id] = substr($1, length(arr[1]) + 2)
        next
    }

    FILENAME==ARGV[5] && FNR > 1 {
        split($1, arr, "-")
        id_to_plddt[arr[2]] = $2
        next
    }

    END {
        for (id in ids) {
            num_anno_pro = id2num_anno_pro[id]
            is_anno = id2is_anno[id]
            mem_anno_level = id in id2mem_anno_level ? id2mem_anno_level[id] : ""
            rep_len = id2len[id]
            rep_name = id2name[id]

            members = ids[id]
            gsub(";", ",", members)
            split(members, arr, ",")
            plddts = 0
            cnt = 0
            for (i in arr) {
                plddts += id_to_plddt[arr[i]]
                cnt ++
            }
            avg_plddt = plddts / cnt


            print id"\t"ids[id]"\t"num_anno_pro"\t"is_anno"\t"mem_anno_level"\t"rep_len"\t"rep_name"\t"avg_plddt
        }
    }
' $target_clusters $metal_anno $membrane_anno - $pred_result > $result