# input
pdb_files="./tmp/20230501_20250501_pdb.tsv"
# output
metal_sites="./data/metal_sites.tsv"
metal_chains="./data/metal_chains.tsv"
# tmp
log_file="./tmp/cmd.log"
mbp_files="./tmp/mbp_files.tsv"
mbp_fasta="./tmp/mbp.fasta"
nr_metal_sites="./tmp/nr_metal_sites.tsv"
nr_metal_sites_fasta="./tmp/nr_metal_sites.fasta"
nr_pdb_files="./tmp/nr_mbp_files.tsv"

source ~/mamba.rc
conda activate metalnet2

metalnet2_prj_dir=$1
scripts_dir=$metalnet2_prj_dir/dataset/collect/scripts

python $scripts_dir/get_metal_binding_proteins.py \
    --input $pdb_files \
    --output_records $mbp_files \
    --output_fasta $mbp_fasta \
    --resolution_threshold 3.0 >> $log_file 2>&1

python $scripts_dir/get_metal_binding_residues.py \
    --input $mbp_files \
    --include_metal_compound \
    --include_common_metal_only \
    --include_water \
    --include_main_chain \
    --output $metal_sites >> $log_file 2>&1

python $scripts_dir/filter_by_seq_identity.py \
    --input_fasta $mbp_fasta \
    --input_pdb $mbp_files \
    --input_records $metal_sites \
    --output_records $nr_metal_sites \
    --output_fasta $nr_metal_sites_fasta \
    --output_pdb $nr_pdb_files >> $log_file 2>&1

python $scripts_dir/transfer_annotations.py \
    --input_records $nr_metal_sites \
    --input_pdb $nr_pdb_files \
    --output_records $metal_chains >> $log_file 2>&1