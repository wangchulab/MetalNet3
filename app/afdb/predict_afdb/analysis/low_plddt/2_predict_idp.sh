# input
fasta_file="./tmp/low_plddt_high_proba.fasta"
aiupred_dir=$1
# output
pred_file="./tmp/idp.pred"

source ~/mamba.rc
mamba activate aiupred

python $aiupred_dir/aiupred.py -i $fasta_file -o $pred_file