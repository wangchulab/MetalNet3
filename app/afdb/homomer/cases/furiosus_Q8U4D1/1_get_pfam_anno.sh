# input
pfam_site_anno="../../../collect_annotation/pfam/data/entryId-pfamId-start-end.tsv"
uni_site_anno="../../../collect_annotation/uniprot/data/entryId-seqNum-resi-metalResi.tsv"
# output
output_dir="./tmp/"

pfams=(PF01380 PF13522)


for p in ${pfams[@]}
do
awk -v pfamId=$p '
    NR==FNR {
        if ($2 == pfamId) {
            ids[$1]
        }
        next
    }
    $1 in ids { 
        print $0
    }

' $pfam_site_anno $uni_site_anno > $output_dir/${p}_mbp_site_anno.tsv
done