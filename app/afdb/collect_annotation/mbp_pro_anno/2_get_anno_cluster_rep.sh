# input
afdb_seq_clsuter_file="../../_database/afdb_clusters/7-AFDB50-repId_memId.tsv"
afdb_struct_cluster_file="../../_database/afdb_clusters/1-AFDBClusters-entryId_repId_taxId.tsv"
mbp_ids_file="./data/entryId.tsv"

# output:
# annoLevel: 
#   1 - there are mbp members in this seq cluster
#   2 - there are no mbps in this seq cluster, but the struct cluster it belongs to has member with label 1
mbp_repId_annoLevel_file="./data/mbp_repId-annoLevel.tsv"

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
    rm $seq_rep_ids_file $struct_rep_ids_file
}

get_go_cluster $mbp_ids_file $mbp_repId_annoLevel_file