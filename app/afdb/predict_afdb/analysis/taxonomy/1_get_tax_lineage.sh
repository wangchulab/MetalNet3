# input
afdb_tax_ids_file="./tmp/afdb50_repId-entryId-taxId.tsv"
# output
tax_id_to_lineage="./tmp/taxId-lineage.tsv"

awk -F'\t' '{print $3}' $afdb_tax_ids_file | sort -u | taxonkit reformat -I 1 -f "{k}|{K}" > $tax_id_to_lineage