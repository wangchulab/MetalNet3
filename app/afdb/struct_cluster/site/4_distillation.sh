# input
anno_info="./tmp/pdb_anno_entryId_structRepId.tsv"
site_info="./data/seqId-site-minPlddt.tsv"
site_struct_rep="./tmp/structRepId-entryId.tsv"
# output
no_pdb_anno_high_conf="./tmp/distillation_seqId-site-minPlddt.tsv"



awk '
    NR==FNR {
        anno_rep_ids[$2];
        next
    }

    FILENAME==ARGV[2] && !($1 in anno_rep_ids)  {
        ids[$2];
        next
    }

    FILENAME==ARGV[3] && FNR>1 && $1 in ids && $3>=70 {
        print $0
    }
' $anno_info $site_struct_rep $site_info > $no_pdb_anno_high_conf