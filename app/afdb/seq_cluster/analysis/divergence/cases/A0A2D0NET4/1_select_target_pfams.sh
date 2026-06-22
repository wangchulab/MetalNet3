# input
pf08818="PF08818"
pf13376="PF13376"
pfam_regions="../../../../../_database/Pfam/Pfam-A.regions.tsv"
afdb50="../../../../../_database/afdb_clusters/7-AFDB50-repId_memId.tsv"
afdb50_cluster_anno="../../../../../collect_annotation/mbp_pro_anno/data/mbp_repId-annoLevel.tsv"
afdb_cluster="../../../../../_database/afdb_clusters/1-AFDBClusters-entryId_repId_taxId.tsv"
high_conf_cluter_info="../../../../data/repId-numPro-numPredPro-numResi-numPredResi-numAnnoPro-isAnno.tsv"
afdb_anno="../../../../../collect_annotation/afdb_anno/data/entryId-repId-pfamId-tedId-annoLevel-sp.tsv"
# output
target_reps="./tmp/entryId-repId.tsv"
rep_info="./tmp/repId-numPro-numPredPro-numSiteAnnoPro-annoLevel-structRepId.tsv"


awk -F'\t' -v pf1=$pf08818 -v pf2=$pf13376 '
    NR==FNR {
        if ($5 == pf1) {
            pf1_ids[$1]
        }
        if ($5 == pf2) {
            pf2_ids[$1]
        }
    }

    END {
        for (id in pf1_ids) {
            if (id in pf2_ids) {
                print id
            }
        }
    }
' $pfam_regions |\
awk -F'\t' -v o1=$target_reps -v o2=$rep_info '
    NR==FNR {
        ids[$1];
        next
    }

    FILENAME==ARGV[2] {
        if ($2 in ids) {
            print $2"\t"$1 >> o1
            rep_ids[$1]
        }
        next
    }

    FILENAME==ARGV[3] {
        if ($1 in rep_ids) {
            rep_to_anno_level[$1] = $2
        }
        next
    }

    FILENAME==ARGV[4] {
        if ($1 in rep_ids) {
            rep_to_num_pred_pro[$1] = $3 
        }
        next
    }

    FILENAME==ARGV[5] {
        if ($2 in rep_ids) {
            rep_to_num_pro[$2] ++
            if (index($5, "3") || index($5, "4")) {
                rep_to_num_site_anno_pro[$2]++
            }
        }
        next
    }

    FILENAME==ARGV[6] {
        if ($1 in rep_ids) {
            rep_to_struct_rep[$1] = $2
        }
        next
    }

    END {
        for (id in rep_ids) {
            num_pro = rep_to_num_pro[id]
            num_pred_pro = id in rep_to_num_pred_pro ? rep_to_num_pred_pro[id] : 0
            num_site_anno_pro = id in rep_to_num_site_anno_pro ? rep_to_num_site_anno_pro[id] : 0
            anno_level = id in rep_to_anno_level ? rep_to_anno_level[id] : ""
            struct_rep = id in rep_to_struct_rep ? rep_to_struct_rep[id] : ""
            print id"\t"num_pro"\t"num_pred_pro"\t"num_site_anno_pro"\t"anno_level"\t"struct_rep >> o2
        }
    }
' - $afdb50 $afdb50_cluster_anno $high_conf_cluter_info $afdb_anno $afdb_cluster