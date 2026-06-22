# input
hign_conf_pred_taxId="./tmp/metaldb_repId-entryId-taxId.tsv"
ids=(243232 83333 559292 39947 9606 309800 330779 224308 1111708)
fasta_files=(
    "../../../_database/fasta/UP000000805_243232.fasta"
    "../../../_database/fasta/UP000000625_83333.fasta"
    "../../../_database/fasta/UP000002311_559292.fasta"
    "../../../_database/fasta/UP000059680_39947.fasta"
    "../../../_database/fasta/UP000005640_9606.fasta"
    "../../../_database/fasta/UP000008243_309800.fasta"
    "../../../_database/fasta/UP000001018_330779.fasta"
    "../../../_database/fasta/UP000001570_224308.fasta"
    "../../../_database/fasta/UP000001425_1111708.fasta"
)

for i in {0..8}
do
id=${ids[$i]}
fasta_file=${fasta_files[$i]}
echo "TaxId: $id"
seqkit fx2tab -n -l $fasta_file | awk '{split($1, arr, "|"); print arr[2]}' |\
awk '
    NR==FNR {
        ids[$1];
        next
    }

    ($2 in ids) {
        cnt++
    }

    END {
        id_count = length(ids)
        ratio = (id_count > 0) ? cnt / id_count : 0
        print "Total: " id_count
        print "High conf predicted: " cnt
        printf "Ratio: %.5f\n", ratio
    }
' - $hign_conf_pred_taxId
echo ""
done

# TaxId: 243232
# Total: 1787
# High conf predicted: 457
# Ratio: 0.25574
# 
# TaxId: 83333
# Total: 4402
# High conf predicted: 818
# Ratio: 0.18582
# 
# TaxId: 559292
# Total: 6065
# High conf predicted: 1040
# Ratio: 0.17148
# 
# TaxId: 39947
# Total: 43668
# High conf predicted: 5888
# Ratio: 0.13484
# 
# TaxId: 9606
# Total: 20650
# High conf predicted: 4513
# Ratio: 0.21855
# 
# TaxId: 309800
# Total: 3922
# High conf predicted: 870
# Ratio: 0.22183
# 
# TaxId: 330779
# Total: 2223
# High conf predicted: 503
# Ratio: 0.22627
# 
# TaxId: 224308
# Total: 4271
# High conf predicted: 731
# Ratio: 0.17115
# 
# TaxId: 1111708
# Total: 3508
# High conf predicted: 619
# Ratio: 0.17645