# copy from "../../../../afdb/collect_annotation/mbp_pro_anno/data/entryId.tsv"

# input
new_uni="./tmp/pdbId-entryId.tsv"
afdb_seq_clsuter_file="../../../../afdb/_database/afdb_clusters/7-AFDB50-repId_memId.tsv"
afdb_struct_cluster_file="../../../../afdb/_database/afdb_clusters/1-AFDBClusters-entryId_repId_taxId.tsv"
mbp_ids_file="../../../../afdb/collect_annotation/mbp_pro_anno/data/entryId.tsv"

# output:
mbp_repId_annoLevel_file="./tmp/mbp_repId-annoLevel.tsv"

get_go_cluster() {
    
    seq_rep_ids_file=$1.seq_rep.tmp
    struct_rep_ids_file=$1.struct_rep.tmp

    awk 'NR==FNR {ids[$1]; next} $2 in ids {print $1}' $1 $afdb_seq_clsuter_file | sort -u > $seq_rep_ids_file
    awk 'NR==FNR {ids[$1]; next} $1 in ids {print $2}' $seq_rep_ids_file $afdb_struct_cluster_file | sort -u > $struct_rep_ids_file
    awk '
        NR==FNR {struct_rep_ids[$1]; next} 
        FILENAME == ARGV[2] {seq_rep_ids[$1]; next} 
        {
            if (($2 in struct_rep_ids) && !($1 in seq_rep_ids)) {
                seq_rep_ids_by_struct[$1]
            }
        }
        END {
            for (id in seq_rep_ids) {
                print id "\t1"
            }
            for (id in seq_rep_ids_by_struct) {
                print id "\t2"
            }
        }
    ' $struct_rep_ids_file $seq_rep_ids_file $afdb_struct_cluster_file > $2
}

awk '
    NR==FNR {
        ids[$2];
        next
    }
    !($1 in ids) {
        print $1
    }
' $new_uni $mbp_ids_file |\
get_go_cluster - $mbp_repId_annoLevel_file