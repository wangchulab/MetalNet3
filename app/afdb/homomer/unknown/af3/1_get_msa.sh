# input
input_fasta="../tmp/no_anno_homomer.fasta"
ids_ref_file="../tmp/pred_no_anno.tsv"
# output
output_msa_dir="./tmp/msa_protenix"

ids=`awk 'NR>1 {print $1}' $ids_ref_file`

seqkit split -i $input_fasta

for i in $ids
do
output_dir=$output_msa_dir/$i
if [ ! -d $output_dir ]; then
mkdir -p $output_dir
fi
done

source ~/mamba.rc
mamba activate protenix
for i in $ids
do
fasta=$input_fasta.split/no_anno_homomer.part_$i.fasta
output_dir=$output_msa_dir/$i
pairing_a3m_file=$output_dir/0/pairing.a3m
if [ ! -f $pairing_a3m_file ]; then
protenix msa --input $fasta --out_dir $output_dir
fi
done