# input
json_with_metal_file="./tmp/protenix_input_with_metal.json"
# output
af3_with_metal_pred_dir="./tmp/pred_struct_with_metal/"

source ~/mamba.rc
mamba activate protenix

CUDA_VISIBLE_DEVICES=3 protenix predict --input $json_with_metal_file --out_dir $af3_with_metal_pred_dir --seeds 42 > 3_pred_af3_with_metal.log 2>&1

# failed cases
# O60296
# Q8NC74
# Q86SQ7
# Q569K6
# Q15276