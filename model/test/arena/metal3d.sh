# input
metal3d_dir=$1
test_cif_dir="./tmp/pdb_cleaned/"
# output
output_dir="./data/metal3d"
probe_dir=$output_dir/probe
log_file=$output_dir/metal3d.log

source ~/mamba.rc
mamba activate metal3d


for i in $test_cif_dir/*cif
do
seq_id=`basename $i`
probe_file=$probe_dir/$seq_id.pdb
echo $i >> $log_file
python $metal3d_dir/Metal3D/metal3d.py \
    --pdb $i \
    --metalbinding \
    --maxp \
    --writeprobes \
    --probefile $probe_file \
    --softexit >> $log_file 2>&1
done

mv ./maxp_metal3d.csv $output_dir