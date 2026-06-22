# input
idmapping="../../_database/idmapping/idmapping_selected.tab"
# output
uniprot_pdb="./tmp/entryId-pdbIds.tsv"

awk -F'\t' '
    $6 != "" {
        gsub("; ", ",", $6)
        gsub(":", "_", $6)
        print $1"\t"$6
    }
' $idmapping > $uniprot_pdb