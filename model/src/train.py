import logging
import sys
import traceback
from pathlib import Path

import hydra
import lightning as L
import pandas as pd
from hydra.core.hydra_config import HydraConfig
from omegaconf import DictConfig, OmegaConf
from utils.encoder import encode_resi, from_fasta_to_encoding, get_encoder
from utils.trainer import Trainer, get_trainer


def encode(cfg: DictConfig):

    logging.info("Extracting encoding...")
    struct_fasta = None
    if cfg.plm.type == "saprot":
        struct_fasta = cfg.fasta.struct_file.saprot
    elif cfg.plm.type == "prosst":
        struct_fasta = cfg.fasta.struct_file.prosst
    struct_fasta_file = (
        Path(cfg.fasta_dir) / struct_fasta if struct_fasta is not None else None
    )

    encoder = get_encoder(cfg.plm.type, Path(cfg.plm_dir) / cfg.plm.file, cfg.device)
    id2encoding = from_fasta_to_encoding(
        encoder=encoder,
        fasta_file=Path(cfg.fasta_dir) / cfg.fasta.seq_file,
        struct_fasta_file=struct_fasta_file,
    )

    df_train_encoded = None
    df_test_encoded = None
    if cfg.mode == "tune":
        df_train_encoded = encode_resi(
            pd.read_table(Path(cfg.dataset_dir) / cfg.dataset.train_file), id2encoding
        )
    elif cfg.mode == "train":
        df_train_encoded = encode_resi(
            pd.read_table(Path(cfg.dataset_dir) / cfg.dataset.train_file), id2encoding
        )
        df_test_encoded = encode_resi(
            pd.read_table(Path(cfg.dataset_dir) / cfg.dataset.test_file), id2encoding
        )
    del id2encoding
    logging.info("Done.")

    return df_train_encoded, df_test_encoded


def tune(
    trainer: Trainer,
    df_train_data: pd.DataFrame,
):
    logging.info("Tuning...")
    df_report = trainer.tune_loop(df_train_data)
    logging.info(
        f"Average performance: \n{df_report.to_string(max_rows=None, max_cols=None)}"
    )

    return df_report


def train(
    trainer: Trainer,
    df_train_data: pd.DataFrame,
    df_test_data: pd.DataFrame,
):
    logging.info(f"Training...")
    _, result = trainer.tune(
        df_train_data,
        df_test_data,
        output_dict=False,
    )
    logging.info(f"Performance on test dataset: \n{result}")


@hydra.main(version_base=None, config_path="./cfg/", config_name="config")
def main(cfg: DictConfig):
    logging.info(f"Config: \n{OmegaConf.to_yaml(cfg)}")
    L.seed_everything(cfg.seed)

    trainer = get_trainer(
        cfg.model,
        cfg.dataset.problem_type,
        HydraConfig.get().runtime.output_dir,
        device=cfg.device,
    )
    df_train_data, df_test_data = encode(cfg)
    try:
        if cfg.mode == "tune":
            assert df_train_data is not None
            result = tune(trainer, df_train_data)
            # return float value for hydra-optuna
            return result.loc[cfg.model.eval_label][cfg.model.eval_metric]["mean"]
        elif cfg.mode == "train":
            assert df_train_data is not None
            assert df_test_data is not None
            result = train(trainer, df_train_data, df_test_data)
    except Exception:
        traceback.print_exc(file=sys.stderr)
        raise


if __name__ == "__main__":
    main()
