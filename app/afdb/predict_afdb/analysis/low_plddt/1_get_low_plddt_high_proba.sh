# input
plddt_proba_file="../../data/pred_site_plddt_proba.tsv"
high_conf_fasta="../../tmp/fasta/pred_ge_3_clique_3.fasta"
# output
low_plddt_pred="./tmp/low_plddt_high_proba.tsv"
low_plddt_fasta="./tmp/low_plddt_high_proba.fasta"

awk -F '\t' '
    NR==1 {
        print $0
    }

    NR>1 {

        split($3, arr_plddt, ",")
        split($4, arr_proba, ",")
        max_plddt = 0
        min_proba = 1
        for (i in arr_plddt) {
            if (arr_plddt[i] > max_plddt) {
                max_plddt = arr_plddt[i]
            }
        }
        for (i in arr_proba) {
            if (arr_proba[i] < min_proba) {
                min_proba = arr_proba[i]
            }
        }

        if (max_plddt < 50 && min_proba >= 0.8) {
            print $0
        }
    }
' $plddt_proba_file > $low_plddt_pred

awk 'NR>1 {print "AFDB:AF-"$1"-F1"}' $low_plddt_pred | sort -u | seqkit grep -f - $high_conf_fasta > $low_plddt_fasta