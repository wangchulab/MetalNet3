# input
json_file="./tmp/protenix_input.json"
# output
af3_pred_dir="./tmp/pred_struct/"

source ~/mamba.rc
mamba activate protenix

protenix predict --input $json_file --out_dir $af3_pred_dir --seeds 42