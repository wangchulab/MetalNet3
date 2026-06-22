# input
new_chains="./tmp/metal_chains.fasta"
metalnet_chains="../../../data/fasta/metalnet.fasta"
metalnet_train_dataset="../../../data/dataset/metalnet_train_ched.tsv"
# tmp
metalnet_train_fasta="./tmp/metalnet_train.fasta"
merged_fasta="./tmp/merged.fasta"
mmseqs_dir="./tmp/mmseqs/"

awk 'NR>1 {print $1}' $metalnet_train_dataset | sort -u | seqkit grep -f - $metalnet_chains > $metalnet_train_fasta
cat $new_chains >> $merged_fasta
cat $metalnet_train_fasta >> $merged_fasta

source ~/mamba.rc
mamba activate metalnet2

mmseqs easy-cluster $merged_fasta result $mmseqs_dir --min-seq-id 0.3 -v 1

rm *fasta
mv "result_cluster.tsv" "./data/"