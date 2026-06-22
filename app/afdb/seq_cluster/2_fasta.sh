# input
afdb_fasta_dir="../_database/fasta/afdb/"
pred_cluster_file="./tmp/high_conf_pred_repId-entryId.tsv"
# output
pred_cluster_fasta_file="./tmp/high_conf_pred_cluster.fasta"

count=0
for i in "$afdb_fasta_dir"/* # we've split afdb fasta file into parts
do
count=$((count + 1))
awk '{print "AFDB:AF-"$2"-F1"}' $pred_cluster_file | seqkit grep -f - $i > ./data/$count.fas
done

cat ./data/*.fas > $pred_cluster_fasta_file
rm ./data/*.fas