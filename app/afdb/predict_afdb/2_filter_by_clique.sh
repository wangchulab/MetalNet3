# input
foldcomp_db="../_database/foldcomp/afdb_uniprot_v4"
pred="./data/pred.tsv"
# tmp
pred_with_at_least_three_residues="./tmp/pred_ge_3.tsv"
# output
pred_clique="./data/pred_ge_3_clique_3.tsv"

awk 'FNR==1 {print $0} FNR>1 && split($2, dummy, ",") >= 3 {print $0}' $pred > $pred_with_at_least_three_residues

source ~/mamba.rc
mamba activate metalnet-helper

# ~ 5 hours if parallel on 20 jobs
python ./scripts/filter.py \
    --foldcomp_db $foldcomp_db \
    --input $pred_with_at_least_three_residues \
    --output $pred_clique