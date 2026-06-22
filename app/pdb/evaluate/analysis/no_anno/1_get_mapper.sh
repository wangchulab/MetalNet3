# input
new_pdb_file="../../../collect_mbp/data/metal_chains.tsv"
cluster_file="../../data/result_cluster.tsv"
uni_to_pdbs_file="../../../../afdb/collect_annotation/pdb/tmp/entryId-pdbIds.tsv"
# output
novel_pdb_to_uni="./tmp/pdbId-entryId.tsv"
# tmp
novel_pdb_file="./tmp/novel_pdb_ids.tsv"

awk '
    NR==FNR && FNR > 1 {
        new_pdb_ids[$1"_"$2];
        next
    }

    {
        id_to_rep[$2] = $1
        if (!($2 in new_pdb_ids)) {
            excluded_reps[$1]
        }
    }

    END {
        for (i in id_to_rep) {
            rep_id = id_to_rep[i]
            if (!(rep_id in excluded_reps)) {
                print i
            }
        }
    }
' $new_pdb_file $cluster_file > $novel_pdb_file

awk '
    NR==FNR {
        ids[toupper($1)] = "";
        next
    }

    {
        split($2, arr, ",")
        for (i in arr) {
            if (arr[i] in ids) {
                ids[arr[i]] = $1
            }
        }
    }

    END {
        for (i in ids) {
            if (ids[i] != "") {
                print tolower(i)"\t"ids[i]
            }
        }
    }

' $novel_pdb_file $uni_to_pdbs_file > $novel_pdb_to_uni