# input 
high_conf_pred_file="../predict_afdb/data/pred/pred_ge_3_clique_3.tsv"
high_conf_pred_interface_file="../homomer/data/pred_homomer_interface.tsv"
human_ref_proteome_fasta="../_database/fasta/UP000005640_9606.fasta"
# output
human_high_conf_pred_file="./tmp/human_high_conf_pred.tsv"
human_high_conf_pred_interface_file="./tmp/human_high_conf_interface_pred.tsv"
human_ids="./tmp/human_ids"

seqkit fx2tab -n -l $human_ref_proteome_fasta | awk '{split($1, arr, "|"); print arr[2]}' > $human_ids
awk -F'\t' '
    NR==FNR {human_ids[$1]; next}
    FNR==1 { print $0 }
    FNR>1 {
        split($1, arr, "-"); 
        if (arr[2] in human_ids) {
            print $0
        }
    }
' $human_ids $high_conf_pred_file > $human_high_conf_pred_file

awk '
    NR==FNR {human_ids[$1]; next}
    FNR==1 { print $0 }
    FNR>1 {
        split($1, arr, "-"); 
        if (arr[2] in human_ids) {
            print $0
        }
    }
' $human_ids $high_conf_pred_interface_file > $human_high_conf_pred_interface_file