# input
sampled="./data/sampled.tsv"
all_pred_fasta="../../../tmp/pred_ge_3_clique_3.fasta"
all_pred_file="../../../data/pred_ge_3_clique_3.tsv"
# tmp
sampled_fasta="./tmp/sampled.fasta"
pred_file_partial="./tmp/sampled_pred_partial.tsv"
# output
pred_file="./data/sampled_pred.tsv"

if [ ! -f $sampled_fasta ]; then
    awk '{print "AFDB:AF-"$1"-F1"}' $sampled | seqkit grep -f - $all_pred_fasta > $sampled_fasta
fi

if [ ! -f $pred_file_partial ]; then
    awk '
        NR==FNR {
            ids["AFDB:AF-"$1"-F1"];
            next
        }
        NR!=FNR && FNR == 1 {
            print $0
        }

        NR!=FNR && FNR > 1 {
            if ($1 in ids) {
                print $0
            }
        }
    ' $sampled $all_pred_file > $pred_file_partial
fi

source ~/mamba.rc
mamba activate metalnet-seq

project_dir="../../../../../../"
presets=(metal_type metal_group_type)
device=cuda:2
for preset in ${presets[@]}
do
python $project_dir/model/src/predict.py \
    preset=$preset \
    model_path=$project_dir/model/train/models/$preset/preset \
    plm_dir=$project_dir/data/models \
    device=$device \
    input_fasta=$sampled_fasta \
    output_pred=${sampled_fasta}.${preset}
done

python $project_dir/model/src/merge.py \
    --p_path $pred_file_partial \
    --tp_path ${sampled_fasta}.${presets[0]} \
    --gtp_path ${sampled_fasta}.${presets[1]} \
    --output_file $pred_file