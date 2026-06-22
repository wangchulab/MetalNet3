# input
fasta_dir="./tmp/clustalo/"
pros="../data/human_potential_258.tsv"
# output

ids=`awk 'NR>1 {print $1}' $pros`

for i in $ids
do
dir=$fasta_dir/$i
fasta_file=$dir/$i.fasta
aligned_file=$dir/$i.clu
clustalo-1.2.4-Ubuntu-x86_64 --in $fasta_file --outfmt=clu --threads=20 > $aligned_file
done