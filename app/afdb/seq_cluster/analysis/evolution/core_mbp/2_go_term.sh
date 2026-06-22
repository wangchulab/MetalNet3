# input
rep_file="./tmp/core_repId-lca-numDomains.tsv"
goa_file="../../../../_database/go/goa_uniprot_all.gaf"
# output
rep_go_terms="./data/rep_go_terms.tsv"

awk '
    NR==FNR {
        ids[$1];
        next;
    }

    /^[!]/ {next}
    $2 in ids && $4 !~ /^NOT/ && $1 == "UniProtKB" {
        id2go[$2] = id2go[$2] ? id2go[$2] ";" $5 : $5
    }

    END {
        for (id in id2go) {
            print id "\t" id2go[id]
        }
    }
'  $rep_file $goa_file > $rep_go_terms