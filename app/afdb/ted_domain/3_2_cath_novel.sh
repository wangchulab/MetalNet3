# input
domain_file="./tmp/pred_rep_domain.tsv"
seq_cluster="../_database/encyclopedia_of_domains/ted_324m_seq_clustering.cathlabels.tsv"
ted_novel_domain="../_database/encyclopedia_of_domains/novel_folds_set.domain_summary.tsv"
ted_symm_domain="../_database/encyclopedia_of_domains/high_symmetry_folds_set.domain_summary.tsv"
# tmp
domain_info_file="./data/repId-hasCATH-isNovel-isSymm.tsv"

awk -F'\t' '
    NR==FNR {
        rep_ids[$4];
        next
    }
    FILENAME==ARGV[2] {
        if ($3 != "-") {
            cath_rep_ids[$1]
        }
        next
    }
    FILENAME==ARGV[3] {
        novel_rep_ids[$1];
        next
    }
    FILENAME==ARGV[4] {
        symm_rep_ids[$1];
        next
    }

    END {
        for (i in rep_ids) {
            has_cath = (i in cath_rep_ids ? 1 : 0)
            is_novel = (i in novel_rep_ids ? 1: 0)
            is_symm = (i in symm_rep_ids ? 1: 0)
            print i"\t"has_cath"\t"is_novel"\t"is_symm
        }
    }
' $domain_file $seq_cluster $ted_novel_domain $ted_symm_domain > $domain_info_file

wc -l $domain_info_file # 11746515
awk '{sum += $2; next} END {print sum}' $domain_info_file # 8116142
awk '{sum += $3; next} END {print sum}' $domain_info_file # 1085
awk '{sum += $4; next} END {print sum}' $domain_info_file # 674