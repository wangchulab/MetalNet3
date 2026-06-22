# input
afdb_fasta_file="../../_database/afdb/afdb_uniprot_v4_fasta"
pdb_metal_anno_file="./tmp/pdb_metal_anno.tsv"
# output
fasta_file="./tmp/uniprot_metal_anno.fasta"

awk 'NR>1 {print "AF-"$1"-F1-model_v4.cif.gz"}' $pdb_metal_anno_file | seqkit grep -f - $afdb_fasta_file > $fasta_file.tmp
seqkit fx2tab $fasta_file.tmp | awk '{split($1, arr, "-"); print "AFDB:AF-"arr[2]"-F1""\t"$2}' | seqkit tab2fx - > $fasta_file
rm $fasta_file.tmp

# fasta_file 7557
# pdb_metal_anno_file 8165