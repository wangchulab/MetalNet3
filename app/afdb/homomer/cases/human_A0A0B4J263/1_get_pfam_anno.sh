# input
pfam_site_anno="../../../collect_annotation/pfam/data/entryId-pfamId-start-end.tsv"
uni_site_anno="../../../collect_annotation/uniprot/data/entryId-seqNum-resi-metalResi.tsv"
# output
output="./tmp/PF07686_mbp_site_anno.tsv"


awk '
    NR==FNR {
        if ($2 == "PF07686") {
            ids[$1]
        }
        next
    }
    $1 in ids { 
        print $0
    }

' $pfam_site_anno $uni_site_anno > $output