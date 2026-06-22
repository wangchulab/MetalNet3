# input
denovo_ids_file="./data/pdb_denovo-is_designed-desc.tsv" # use "DE NOVO PROTEIN" in Structure Keywords -> has exact phrase
# output
target_file="./tmp/denovo_mbp_ids.tsv"

awk -F'\t' '$2==1 {print $1}' $denovo_ids_file | sort > $target_file