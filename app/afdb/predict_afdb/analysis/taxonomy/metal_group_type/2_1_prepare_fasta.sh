
# input
metaldb_fasta_file="../../../tmp/pred_ge_3_clique_3.fasta"
sampled_file="./tmp/sampled_600k_repId-entryId-domain.tsv"
# output
sampled_fasta="./tmp/sampled_600k.fasta"
pred_input="./tmp/pred_input_files.tsv"


### prepare fasta and input file
awk '{print "AFDB:AF-"$2"-F1"}' $sampled_file | seqkit grep -f - $metaldb_fasta_file > $sampled_fasta
seqkit split -s 10000 $sampled_fasta

### make input files
echo "seq_fasta_file	pred_file" >> $pred_input
for i in $sampled_fasta.split/*.fasta
do
pred_file=`basename $i`
echo "$i	./tmp/pred/$pred_file" >> $pred_input
done