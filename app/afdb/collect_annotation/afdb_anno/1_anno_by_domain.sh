# input
metal_pfam_domains="../pfam/data/pfamId.tsv"
metal_ted_domains="../ted_domain/data/tedId.tsv"
afdb_ted_domains="../ted_domain/tmp/redundantId-entryId-repId-boundaries.tsv"
id2pfam="../../_database/Pfam/Pfam-A.regions.tsv"
afdb_file="../../_database/afdb_clusters/7-AFDB50-repId_memId.tsv"
# output
ted_anno_output="./tmp/entryId-tedId.tsv"
pfam_anno_output="./tmp/entryId-pfamId.tsv"

awk -F'\t' '
    NR==FNR {
        ids[$1];
        next
    }
    FILENAME==ARGV[2] && FNR > 1 {
        if ($5 in ids) {
            entry_to_pfam[$1] = $5
        }
        next
    }
    FILENAME==ARGV[3] {
        if ($2 in entry_to_pfam) {
            print $2"\t"entry_to_pfam[$2]
        }
    }
' $metal_pfam_domains $id2pfam $afdb_file > $pfam_anno_output

awk -F'\t' '
    NR==FNR {
        ids[$1];
        next
    }

    FILENAME==ARGV[2] && $3 in ids {
        if ($1 != "") {
            split($1, arr, "-")
            id_to_ted[arr[2]] = $2 
        } else {
            split($2, arr, "-")
            id_to_ted[arr[2]] = $2 
        }
    }

    FILENAME==ARGV[3] {
        if ($2 in id_to_ted) {
            print $2"\t"id_to_ted[$2]
        }
    }
' $metal_ted_domains $afdb_ted_domains $afdb_file > $ted_anno_output