# input
input_file="./tmp/pred_input_files.tsv"
pred_dir="./tmp/pred/"


### run pred
source ~/mamba.rc
mamba activate metalnet-seq
project_dir="../../../../../../"

presets=(metal_group_type)
for preset in ${presets[@]}
do
python $project_dir/model/src/predict.py \
    preset=$preset \
    model_path=$project_dir/model/train/models/$preset/preset \
    plm_dir=$project_dir/data/models \
    input_files=$input_file \
    pred_file_suffix=".$preset"
done