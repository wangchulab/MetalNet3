# input
json_file="./tmp/protenix_input.json"
pred_dir="./tmp/pred_struct"

source ~/mamba.rc
mamba activate protenix

protenix predict --input $json_file --out_dir $pred_dir --seeds 42 --use_msa true