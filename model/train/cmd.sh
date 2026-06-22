source ~/mamba.rc
mamba activate metalnet-seq
project_dir=`realpath ../../`

scripts_file=$project_dir/model/src/train.py
dataset_type=metal,metal_type,metal_group_type
plms=esm2-150M,esm2-650M,esm2-3B,saprot-650M-AF2,saprot-650M-PDB,prosst-2048,prott5-xl,ankh-base,ankh-large

model=svm,ag
python $scripts_file --multirun \
    project_dir=$project_dir \
    plm=$plms \
    model=$model \
    dataset=$dataset_type \

# nn specific    
python $scripts_file --multirun \
    project_dir=$project_dir \
    plm=$plms \
    model=nn \
    dataset=metal
python $scripts_file --multirun \
    project_dir=$project_dir \
    plm=$plms \
    model=nn_metal_type \
    dataset=metal_type
python $scripts_file --multirun \
    project_dir=$project_dir \
    plm=$plms \
    model=nn_metal_group_type \
    dataset=metal_group_type
    