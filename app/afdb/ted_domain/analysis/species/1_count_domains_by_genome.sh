# input
high_conf_pred_domains="../../tmp/entryId-tedIds-posis.tsv"
all_domains="../../../collect_annotation/ted_domain/tmp/redundantId-entryId-repId-boundaries.tsv"
ids=(243232 83333 559292 39947 9606)
fasta_files=(
    "../../../../../_database/fasta/UP000000805_243232.fasta"
    "../../../../../_database/fasta/UP000000625_83333.fasta"
    "../../../../../_database/fasta/UP000002311_559292.fasta"
    "../../../../../_database/fasta/UP000059680_39947.fasta"
    "../../../../../_database/fasta/UP000005640_9606.fasta"
)

for i in {0..4}
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

    NR!=FNR {
        if ($1 != "") {
            split($1, arr, "-")
            if (arr[2] in ids) {
                domain_cnt++
            }
        } else {
            split($2, arr, "-")
            if (arr[2] in ids) {
                domain_cnt++
            }
        }
    }

    END {
        print domain_cnt
    }
' - $all_domains
echo ""
done

# TaxId: 243232
# 3146
# 
# TaxId: 83333
# 7614
# 
# TaxId: 559292
# 11418
# 
# TaxId: 39947
# 52673
# 
# TaxId: 9606
# 39525


for i in {0..4}
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

    NR!=FNR && $1 in ids {
        domain_cnt += gsub(/,/, "", $2) + 1
    }

    END {
        print "Predicted: " domain_cnt
    }
' - $high_conf_pred_domains
echo ""
done

# TaxId: 243232
# Predicted: 509
# 
# TaxId: 83333
# Predicted: 864
# 
# TaxId: 559292
# Predicted: 1079
# 
# TaxId: 39947
# Predicted: 5462
# 
# TaxId: 9606
# Predicted: 5867