# input
ids="A0A844YVV8 A0A0Q2UZ21 A0A0W1QLT8 A0A7Y0BPB7 A0A371XES9 A0A420ECL8 A0A2C6ZAS9 A0A0Q6F3B2 A0A117UZN8 A0A844YE25"
fasta_file="./tmp/PF06904.fasta"
# output
aligned_file="./tmp/PF06904.clu"


awk -v ids="$ids" '
BEGIN {
    split(ids, id_arr, " ")
    for (i in id_arr) {
        print "AFDB:AF-"id_arr[i]"-F1"
    }
}
' | seqkit grep -f - $fasta_file | clustalo-1.2.4-Ubuntu-x86_64 --in - --outfmt=clu --threads=20 > $aligned_file
