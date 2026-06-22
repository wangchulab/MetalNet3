# input
unknown_ted_file="../data/cat-pdbIds-tedRepIds.tsv"
ted_clulster_file="../../../../_database/encyclopedia_of_domains/ted_324m_seq_clustering.cathlabels.tsv"
ted_boundary_file="../../../../_database/encyclopedia_of_domains/ted_365m_domain_boundaries_consensus_level.tsv"
pred_ted_site_id_file="../../../analysis/site_domain_composition/tmp/repId-tedId-entryId-siteId-siteKind.tsv"
pred_result_with_ted_file="../../../analysis/site_domain_composition/tmp/entryId-sites-tedIds.tsv"
cat=$1
# output
target_ted_cluster=$2

grep $cat $unknown_ted_file |\
awk '{ split($3, arr, ","); for (i in arr) { print arr[i] } }' - |\
awk -v cat="$cat" '
    NR==FNR {
        ted_rep_ids[$1];
        next
    }

    $1 in ted_rep_ids {
        print $1"\t"$2"\t"$3
    }
' - $ted_clulster_file |\
awk '
    NR==FNR {
        ted_id_to_rep_id[$2] = $1
        ted_id_to_cath[$2] = $3
        split($2, arr, "-")
        entry_ids[arr[2]] = (arr[2] in entry_ids) ? entry_ids[arr[2]] "," $2 : $2
        next
    }

    FILENAME==ARGV[2] {
        if ($2 in ted_id_to_cath && $3 in entry_ids) {
            ted_id_to_site_ids[$2] = ($2 in ted_id_to_site_ids) ? ted_id_to_site_ids[$2] "," $4 : $4
        }
        next
    }

    FILENAME==ARGV[3] {
        if ($1 in entry_ids) {
            split(entry_ids[$1], arr_ted, ",")
            split($2, arr_site, ";")
            for (i in arr_ted) {
                ted_id = arr_ted[i]
                if (ted_id == "") continue # why there is emtpy?
                split(ted_id_to_site_ids[ted_id], arr_site_id, ",")
                site_str = ""
                for (j in arr_site_id) {
                    site_id = arr_site_id[j]
                    site_str = site_str == "" ? arr_site[j] : (site_str ";" arr_site[j])
                }

                print ted_id_to_rep_id[ted_id]"\t"ted_id"\t"ted_id_to_cath[ted_id]"\t"site_str
            }
        }
        next
    }

    END {
        for (i in ted_id_to_rep_id) {
            if (!(i in ted_id_to_site_ids)) {
                print ted_id_to_rep_id[i]"\t"i"\t"ted_id_to_cath[i]"\t"""
            }
        }
    }

' - $pred_ted_site_id_file $pred_result_with_ted_file |\
awk '
    NR==FNR {
        ids[$2] = $0
        next
    }

    $1 in ids {
        print ids[$1]"\t"$2
    }
' - $ted_boundary_file | sort -u > $target_ted_cluster
