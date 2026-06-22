# input
filter_file="../filter/data/filtered.tsv"
fasta_file="../filter/tmp/no_anno.fasta"
# output
clean_pred="./tmp/clean_maxsep.csv"
# tmp
clean_fasta_file="./tmp/clean.fasta"


awk 'NR>1 {print "AFDB:AF-"$1"-F1"}' $filter_file | seqkit grep -f - $fasta_file | seqkit replace -p " .*" -r "" > $clean_fasta_file

# in CLEAN env:
# mamba activate clean
# python CLEAN_infer_fasta.py --fasta_data clean
