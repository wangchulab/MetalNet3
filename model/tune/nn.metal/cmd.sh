source ~/mamba.rc
mamba activate metalnet-seq

project_dir=`realpath ../../../`
scripts_file=$project_dir/model/src/train.py

opt() {
    python $scripts_file --multirun \
        project_dir=$project_dir \
        mode=tune \
        model=nn \
        dataset=metal \
        plm=esm2-650M \
        hydra/sweeper=optuna \
        hydra/sweeper/sampler=grid \
        hydra.sweeper.direction=maximize \
        hydra.sweeper.n_trials=30 \
        hydra.sweeper.n_jobs=5 \
        "$@"
}

opt_lr_and_num_hidden_layers() {
    opt \
        'model.learning_rate=choice(0.1, 0.01, 0.001, 0.0001, 0.00001)' \
        'model.num_hidden_layers=choice(0, 1, 2, 3)'
}

# >>> input:
# opt_lr_and_num_hidden_layers > cmd.log 2>&1

# >>> output:
# name: optuna
# best_params:
#   model.learning_rate: 0.01
#   model.num_hidden_layers: 3
# best_value: 0.7799147842929065

opt_sampler_and_loss() {
    opt \
        'model.use_weighted_sampler=choice(true, false)' \
        'model.use_ce_loss_weights=choice(true, false)' \
        'model.focal_loss_gamma=choice(0.0, 1.0, 2.0, 3.0)'
}

# >>> input:
# opt_sampler_and_loss > cmd.log 2>&1

# >>> output:
# name: optuna
# best_params:
#   model.use_weighted_sampler: false
#   model.use_ce_loss_weights: true
#   model.focal_loss_gamma: 0.0
# best_value: 0.7799147842929065

opt_hidden_dim_and_dropout() {
    opt \
        'model.hidden_dim=choice(64, 128, 256, 512, 1024)' \
        'model.dropout=choice(0, 0.1, 0.2, 0.3, 0.4, 0.5)'
}

# >>> input:
# opt_hidden_dim_and_dropout > cmd.log 2>&1

# >>> output:
# name: optuna
# best_params:
#   model.hidden_dim: 128
#   model.dropout: 0.4
# best_value: 0.7832147991610322

opt_batch_size() {
    opt \
        'model.batch_size.train=choice(256, 1024, 4096, 16384, 65536)'
}

# >>> input:
# opt_batch_size > cmd.log 2>&1

# >>> output:
# name: optuna
# best_params:
#   model.batch_size.train: 16384
# best_value: 0.7832147991610322