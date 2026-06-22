# input
site_anno_file="../mbp_site_anno/data/entryId-seqNum-resi-metalResi.tsv"
go_term_anno_file="../go_terms/data/mbp_uniprot_id.tsv"
# output
pro_anno_file="./data/entryId.tsv"

awk '
    NR==FNR {
        print $1
        ids[$1]
        next
    }

    !($1 in ids) {
        print $1
    }
' $go_term_anno_file $site_anno_file > $pro_anno_file