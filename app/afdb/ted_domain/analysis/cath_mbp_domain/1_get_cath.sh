# input
anno_domain_file="../../../../../collect_annotation/ted_domain/tmp/repId-hasCATH-isNovel-isSymm.tsv"
pred_domain_file="../../data/repId-hasCATH-isNovel-isSymm.tsv"
ted_cluster_file="../../../../../_database/encyclopedia_of_domains/ted_324m_seq_clustering.cathlabels.tsv"
# output
anno_domain_cath_file="./tmp/anno_repId-cath.tsv"
pred_domain_cath_file="./tmp/pred_repId-cath.tsv"


get_domain_rep_cath_label() {
    awk -F'\t' '
        NR==FNR {
           ids[$1]
           next; 
        }

        $1 in ids && $3 != "-" {
            print $1"\t"$3
        }
    ' $1 $2 | sort -u
}

get_domain_rep_cath_label $anno_domain_file $ted_cluster_file > $anno_domain_cath_file &
get_domain_rep_cath_label $pred_domain_file $ted_cluster_file > $pred_domain_cath_file &
wait