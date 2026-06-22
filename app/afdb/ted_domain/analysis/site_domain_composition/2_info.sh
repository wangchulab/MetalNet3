# input
domain_file="./tmp/entryId-sites-tedIds.tsv" # protein level
domain_cluster="../../tmp/pred_rep_domain.tsv"
# output
domain_site_file="./tmp/repId-tedId-entryId-siteId-siteKind.tsv"

awk -F'\t' '

    NR==FNR {
        ted_id_to_rep_id[$3] = $4
        next
    }

    {
        split($3, arr, ";")
        for (site_id in arr) {
            s = arr[site_id]
            has_unassigned = index(s, "None")
            multi_involved = index(s, ",")  
            site_kind = has_unassigned ? "u" : (multi_involved ? "m" : "s")

            split(s, arr2, ",")
            for (i in arr2) {
                ted_id = arr2[i]
                if (ted_id != "None") {
                    info = ted_id","$1","site_id","site_kind
                    ted_id_and_site_info[info]
                }
            }
        }
        next
    }

    END {
        for (info in ted_id_and_site_info) {
            split(info, arr, ",")
            ted_id = arr[1]
            rep_id = ted_id_to_rep_id[ted_id]
            entry_id = arr[2]
            site_id = arr[3]
            site_kind = arr[4]
            print rep_id"\t"ted_id"\t"entry_id"\t"site_id"\t"site_kind
        }
    }
' $domain_cluster $domain_file > $domain_site_file


# total protein
wc -l $domain_file # 38361041
# total site
awk '{ count=gsub(";", ";", $2); total += (count + 1); next } END { print total }' $domain_file # 46143213

awk '$5=='s'' $domain_site_file | wc -l # 32291076
awk '$5=="m" {print $3","$4}' $domain_site_file | sort -u | wc -l # 1649455
awk '$5=="u" {print $3","$4}' $domain_site_file | sort -u | wc -l # 6228694
# has unassigned 12,202,682 (46143213 - 32291076 - 1649455)