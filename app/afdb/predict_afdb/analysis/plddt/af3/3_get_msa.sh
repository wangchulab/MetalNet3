# input
input_fasta="./tmp/sampled.fasta"
ids_ref_file="./data/sampled_pred.tsv"
# output
output_msa_dir="./tmp/msa_protenix"

ids=`awk 'NR>1 {print $1}' $ids_ref_file`

# seqkit split -i $input_fasta
# 
# for i in $ids
# do
# mkdir -p $output_msa_dir/$i
# done

source ~/mamba.rc
mamba activate protenix
for i in $ids
do
fasta=$input_fasta.split/sampled.part_AFDB__AF-$i-F1.fasta
output_dir=$output_msa_dir/$i
pairing_a3m_file=$output_dir/0/pairing.a3m
if [ ! -f $pairing_a3m_file ]; then
protenix msa --input $fasta --out_dir $output_dir
fi
done