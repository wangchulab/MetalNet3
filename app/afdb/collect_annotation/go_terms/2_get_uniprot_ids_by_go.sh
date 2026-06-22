# input
goa_file="../../_database/go/goa_uniprot_all.gaf"
mbp_go_ids_file="./data/mbp_go_id-name.tsv"
enzyme_go_ids_file="./data/enzyme_go_id-name.tsv"
membrane_go_ids_file="./data/membrane_go_id-name.tsv"

# output
output_mbp_uniprot_ids_file="./data/mbp_uniprot_id.tsv"
output_enzyme_uniprot_ids_file="./tmp/enzyme_uniprot_id.tsv"
output_membrane_uniprot_ids_file="./tmp/membrane_uniprot_id.tsv"

extract() {
    awk 'NR==FNR {ids[$1]; next} /^[!]/ {next} $5 in ids && $4 !~ /^NOT/ && $1 == "UniProtKB" {print $2}' $1 $goa_file | sort -u > $2
}
extract $mbp_go_ids_file $output_mbp_uniprot_ids_file &
extract $enzyme_go_ids_file $output_enzyme_uniprot_ids_file &
extract $membrane_go_ids_file $output_membrane_uniprot_ids_file &
wait