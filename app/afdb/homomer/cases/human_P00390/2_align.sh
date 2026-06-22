# input
fasta="./tmp/align_seqs.fasta"
# output
output="./tmp/aligned_result.fasta"

~/install/clustalo/clustalo-1.2.4-Ubuntu-x86_64 --in $fasta --outfmt=fasta > $output