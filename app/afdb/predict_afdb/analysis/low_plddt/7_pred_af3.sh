# input
json_file="./tmp/protenix_input.json"
json_with_metal_file="./tmp/protenix_input_with_metal.json"
# output
af3_pred_dir="./tmp/pred_struct/"
af3_with_metal_pred_dir="./tmp/pred_struct_with_metal/"

source ~/mamba.rc
mamba activate protenix

CUDA_VISIBLE_DEVICES=2 protenix predict --input $json_file --out_dir $af3_pred_dir --seeds 42 &
CUDA_VISIBLE_DEVICES=3 protenix predict --input $json_with_metal_file --out_dir $af3_with_metal_pred_dir --seeds 42 &
wait
