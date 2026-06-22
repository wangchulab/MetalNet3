# input
pred="./tmp/sampled_pred_result.tsv"

for i in {0..2}
do
awk -v n="$i" '
    NR>1 &&  gsub(n, "", $4)>=3  {
        cnt[$9]++
    }
    END {
        for (i in cnt) {
            print i, cnt[i]
        }
    }

' $pred
done

# alkaline metals:
# Archaea 44727
# Bacteria 57488
# Eukaryota 27338

# transition metals
# Archaea 117039
# Bacteria 113832
# Eukaryota 166137

# fe-s cluster
# Archaea 29219
# Bacteria 18052
# Eukaryota 2433