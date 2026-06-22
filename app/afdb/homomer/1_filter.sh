# input
# Homomers data (seq_ids and pdbs) come from `An atlas of protein homo-oligomerization across domains of life`.
# Note that: squences in some pdb files are part of the original full sequence in uniprot, thus giving domain in pdb files.
pdb_files="../_database/homomers_four_species/homomer_pdb_files.tsv"
pred_file="../predict_afdb/data/pred.tsv"

# output
pred_homomer_interface="./tmp/filtered_interface.tsv"

# tmp
pred_homomer="./tmp/pred_homomer.tsv"

awk -F'\t' '
    NR==FNR && FNR > 1 {
        ids["AFDB:AF-"$1"-F1"];
        next
    }
    NR != FNR {
        if (FNR == 1) {
            print $0
        } else {
            if ($1 in ids) {
                print $0
            }
        }
    }
' $pdb_files $pred_file > $pred_homomer


source ~/mamba.rc
mamba activate metalnet-seq

python ./scripts/filter_interface.py \
    --pdb_files $pdb_files \
    --input $pred_homomer \
    --output $pred_homomer_interface