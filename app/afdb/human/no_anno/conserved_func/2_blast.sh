# input
human_258_seq="../tmp/filtered.fasta"
target_species="./tmp/entryId-repId-taxId.fasta"
BLAST_EXE_PATH=~/install/ncbi-blast-2.17.0+/bin
# output
target_species_blast="./tmp/blastdb/11_species_blast.db"
blast_out="./tmp/human_258_to_11_species.blast"


${BLAST_EXE_PATH}/makeblastdb -in $target_species -parse_seqids -hash_index -dbtype prot -out $target_species_blast
${BLAST_EXE_PATH}/blastp -query $human_258_seq -out $blast_out -db $target_species_blast -outfmt 6 -evalue 1e-5 -num_threads 30