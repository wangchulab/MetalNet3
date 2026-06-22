# input
site_comp="../../analysis/site_domain_composition/tmp/repId-tedId-entryId-siteId-siteKind.tsv"
novel_ted_cath="./tmp/tedId-cath.tsv"
# output
single_ted_cath="./tmp/single_site_tedId-cath.tsv"

awk -F'\t' '
    NR==FNR {
        if ($5 == "s") {
            ids[$1]
        }
        next
    }

    $1 in ids {
        print $0
    }
' $site_comp $novel_ted_cath > $single_ted_cath