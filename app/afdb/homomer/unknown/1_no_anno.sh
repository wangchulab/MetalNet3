# input
fasta_file="../tmp/pred_homomer.fasta"
pred_info="../data/pred_info.tsv"
# output
no_anno_fasta="./tmp/no_anno_homomer.fasta"
no_anno_homomer="./tmp/pred_no_anno.tsv"

awk -F'\t' 'NR==1 || (NR>1 && $11 == "")' $pred_info > $no_anno_homomer

seqkit fx2tab $fasta_file |\
awk -F'\t' '
    NR==FNR && NR > 1 {
        ids[$1]
        next
    }

    {
        split($1, arr, "-")
        if (arr[2] in ids) {
            print arr[2]"\t"$2
        }
    }

' $ids_file - | seqkit tab2fx - > $no_anno_fasta