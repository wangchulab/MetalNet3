# input
ids_file="../tmp/150_idp_mbp.tsv"
metalnet2_prj_dir=$1
pred_struct_dir="../tmp/pred_struct_with_metal/"
# tmp
input_file="./tmp/sampled_id-file.tsv"
# output
output_file="./tmp/sampled_metal_binding_result.tsv"

source ~/mamba.rc
mamba activate metalnet2

# make input file
if [ ! -f $input_file ]; then
echo -e "pdb\tpdb_file" >> $input_file
ids=`awk 'NR>1 {print $1}' $ids_file`
for id in $ids
do
pdb_file=$pred_struct_dir/$id/"seed_42"/"predictions"/${id}_sample_0.cif
echo -e "$id\t$pdb_file" >> $input_file
done
fi

# collect
scripts_file=$metalnet2_prj_dir/dataset/collect/scripts/get_metal_binding_residues.py
python $scripts_file \
    --input $input_file \
    --output $output_file \
    --interacted_distance 4 \
    --interacted_num_resi 2 \
    --chain_length_threshold -1 \
    --include_common_metal_only \
    --include_metal_compound \
    --include_main_chain \
    --use_sloppy_mode