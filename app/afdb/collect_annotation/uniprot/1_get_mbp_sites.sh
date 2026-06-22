# input
uniprot_txt_trembl="../../_database/txt/uniprot_trembl.dat.gz"
uniprot_txt_swiss="../../_database/txt/uniprot_sprot.dat"
ligands_file="./scripts/metal_ligands.csv"
# tmp
output_trembl="./tmp/trembl.tsv"
output_swiss="./tmp/swiss.tsv"
# output
output="./data/entryId-seqNum-resi-metalResi.tsv"

source ~/mamba.rc
mamba activate metalnet-helper

python "./scripts/extract_site_anno.py" \
    --input_txt $uniprot_txt_trembl \
    --input_ligands $ligands_file \
    --output $output_trembl
# ~10 hour

python "./scripts/extract_site_anno.py" \
    --input_txt $uniprot_txt_swiss \
    --input_ligands $ligands_file \
    --output $output_swiss

cp $output_swiss $output
cat $output_trembl >> $output