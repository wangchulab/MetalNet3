# input
ted_redundant_39m="../../_database/encyclopedia_of_domains/ted_redundant_39m.singlechain.consensus_domain_summary.taxid.tsv"
ted_324m_seq_clustering="../../_database/encyclopedia_of_domains/ted_324m_seq_clustering.cathlabels.tsv"
ted_all="../../_database/encyclopedia_of_domains/ted_365m_domain_boundaries_consensus_level.tsv"
# output:
# 1. all redundant seqs (and their boundaries) are represented by sequences in ted100
# 2. discard sequences that do not have corresponding sequences in ted100
afdb_ted_domain="./tmp/redundantId-entryId-repId-boundaries.tsv"
# tmp
afdb_ted_domain_tmp="./tmp/redundantId-entryId-repId.tsv"

awk -F'\t' '
    NR==FNR && FNR > 1 {
        split($1, arr1, "-")
        split($10, arr2, "-")
        if (!(arr2[2] in redundant_rep_members)) {
            redundant_rep_members[arr2[2]] = arr1[2]
        } else {
            redundant_rep_members[arr2[2]] = redundant_rep_members[arr2[2]]","arr1[2]
        }
        next
    }

    FILENAME==ARGV[2] {
        rep_id = $1
        entry_id = $2
        split(entry_id, arr, "-")
        if (arr[2] in redundant_rep_members) {
            members = redundant_rep_members[arr[2]]
            split(members, arr2, ",")
            for (i in arr2) {
                redundant_uniprot_id = arr2[i]

                redundant_ted_id = arr[1]"-"redundant_uniprot_id"-"arr[3]"-"arr[4]
                print redundant_ted_id"\t"entry_id"\t"rep_id

  
            }
        } else {
            print """\t"entry_id"\t"rep_id
        }

    }
' $ted_redundant_39m $ted_324m_seq_clustering > $afdb_ted_domain_tmp


awk -F'\t' '
    NR==FNR {
        ids[$1] = $2
        next
    }

    {
        print $0"\t"ids[$2]
    }
' $ted_all $afdb_ted_domain_tmp > $afdb_ted_domain

rm $afdb_ted_domain_tmp