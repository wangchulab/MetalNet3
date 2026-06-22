# input
uniprot_human_fasta_file="../_database/fasta/UP000005640_9606.fasta"
afdb_human_file="../_database/afdb_clusters/3-sapId_sapGO_repId_cluFlag_LCAtaxId.tsv"
# output
output_missing_ids_file="./tmp/missing_id-geneName-len.tsv"

seqkit fx2tab -n -l $uniprot_human_fasta_file | awk '{split($1, arr, "|"); print arr[2]"\t"arr[3]"\t"$NF}' |\
awk 'NR==FNR {ids[$1]; next} !($1 in ids) {print $0}' $afdb_human_file - | sort -k3,3n > $output_missing_ids_file