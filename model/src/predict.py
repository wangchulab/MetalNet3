import logging
import time
import traceback
from functools import wraps
from pathlib import Path
from typing import Any, Optional

import hydra
import lightning as L
import pandas as pd
import torch
import tqdm
from hydra.core.hydra_config import HydraConfig
from omegaconf import DictConfig, OmegaConf
from utils.encoder import Encoder, encode_resi, get_encoder, parse_fasta_file
from utils.trainer import ProblemType, Trainer, get_trainer


def timer(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        logging.info(
            f"Function '{func.__name__}' executed in {end - start:.6f} seconds"
        )
        return result

    return wrapper


@timer
def encode(
    encoder: Encoder,
    id2seq: dict,
    df_pred: pd.DataFrame,
    id2struct_seq: Optional[dict],
    toks_per_batch: int,
):
    logging.info("Extracting encoding...")
    id2encoding = encoder.extract(
        id2seq=id2seq, id2struct_seq=id2struct_seq, toks_per_batch=toks_per_batch
    )
    df_pred_encoded = encode_resi(df_pred, id2encoding)
    torch.cuda.empty_cache()
    logging.info("Done.")
    return df_pred_encoded


def seq_from_fasta(seq_fasta_file: str, struct_fasta_file: Optional[str] = None):
    id2seq = parse_fasta_file(seq_fasta_file)
    id2struct_seq = (
        parse_fasta_file(struct_fasta_file) if struct_fasta_file is not None else None
    )
    return id2seq, id2struct_seq


def get_ched_from_seq(id2seq: dict) -> pd.DataFrame:
    ched_records = []
    for id, seq in id2seq.items():
        for idx, aa in enumerate(seq):
            if aa in {"C", "H", "E", "D"}:
                ched_records.append(
                    {
                        "seq_id": id,
                        "resi": aa,
                        "resi_seq_posi": idx,
                    }
                )
    return pd.DataFrame(ched_records)


@timer
def predict(
    trainer: Trainer,
    model: Any,
    df_pred_data: pd.DataFrame,
    proba_cutoff: Optional[float],
    **kwargs,
):
    logging.info(f"Predicting...")
    y_pred_prob = trainer.predict(model, df_pred_data, **kwargs)  # shape (n, C)
    logging.info("Done.")

    df_pred = df_pred_data.drop(columns=["x"])
    if trainer.problem_type == ProblemType.binary:
        df_pred["y_pred_proba"] = y_pred_prob[:, 1].flatten()
        if proba_cutoff is not None:
            df_pred = df_pred[df_pred["y_pred_proba"] >= proba_cutoff]
    elif trainer.problem_type == ProblemType.multiclass:
        df_pred["y_pred"] = y_pred_prob.argmax(axis=-1).flatten()
    else:
        raise ValueError
    return df_pred


def save_data_frame(
    df: pd.DataFrame,
    file_path,
    problem_type: ProblemType,
    use_compact_format: bool,
):
    if not use_compact_format:
        df.to_csv(file_path, sep="\t", index=None)  # type: ignore
        return

    records = []
    for (seq_id,), df_seq in df.groupby(by=["seq_id"]):
        posi = df_seq["resi_seq_posi"].tolist()
        if problem_type == ProblemType.binary:
            pred = df_seq["y_pred_proba"].map(lambda x: round(x, 4)).tolist()
        elif problem_type == ProblemType.multiclass:
            pred = df_seq["y_pred"].tolist()

        records.append(
            {
                "seq_id": seq_id,
                "posi": ",".join([str(i) for i in posi]),
                "pred": ",".join([str(i) for i in pred]),
            }
        )

    if len(records) > 0:
        pd.DataFrame(records).to_csv(file_path, sep="\t", index=None)  # type: ignore


@timer
def predict_multiple_files(
    trainer: Trainer,
    model: Any,
    encoder: Encoder,
    df_files: pd.DataFrame,
    proba_cutoff: Optional[float] = None,
    save_compact_format: bool = False,
    toks_per_batch: int = 4096,
    **kwargs,
):
    for idx, row in tqdm.tqdm(df_files.iterrows(), total=len(df_files)):
        seq_fasta_file = row["seq_fasta_file"]
        struct_fasta_file = (
            row["struct_fasta_file"] if "struct_fasta_file" in row.keys() else None
        )
        pred_file = (
            Path(row["pred_file"])
            if "pred_file" in row.keys()
            else Path(HydraConfig.get().runtime.output_dir) / f"pred_{idx}.tsv"
        )
        if pred_file.exists():
            continue

        try:
            id2seq, id2struct_seq = seq_from_fasta(seq_fasta_file, struct_fasta_file)
            df_pred_encoded = encode(
                encoder,
                id2seq,
                get_ched_from_seq(id2seq),
                id2struct_seq,
                toks_per_batch,
            )
            if len(df_pred_encoded) == 0:
                continue

            df_pred = predict(trainer, model, df_pred_encoded, proba_cutoff, **kwargs)
            save_data_frame(
                df_pred, pred_file, trainer.problem_type, save_compact_format
            )
        except:
            traceback.print_exc()
            logging.error(f"Failed for {seq_fasta_file}")


@hydra.main(version_base=None, config_path="./cfg/", config_name="prediction")
def main(cfg: DictConfig):
    logging.info(f"Config: \n{OmegaConf.to_yaml(cfg)}")
    L.seed_everything(cfg.seed)

    trainer = get_trainer(
        cfg.preset.model,
        cfg.preset.problem_type,
        HydraConfig.get().runtime.output_dir,
        device=cfg.device,
    )
    encoder = get_encoder(
        cfg.preset.plm.type, Path(cfg.plm_dir) / cfg.preset.plm.file, cfg.device
    )
    model = trainer.load_model(cfg.model_path)

    if len(cfg.input_files) != 0:
        df_files = pd.read_table(cfg.input_files)
        if "pred_file" in df_files.columns:
            df_files["pred_file"] = df_files["pred_file"].map(
                lambda x: x + cfg.pred_file_suffix
            )
    elif len(cfg.input_fasta) != 0:
        data = dict()
        data["seq_fasta_file"] = cfg.input_fasta
        if len(cfg.output_pred) != 0:
            data["pred_file"] = cfg.output_pred + cfg.pred_file_suffix
        df_files = pd.DataFrame([data])
    else:
        raise ValueError

    predict_multiple_files(
        trainer,
        model,
        encoder,
        df_files,
        proba_cutoff=cfg.preset.proba_cutoff,
        save_compact_format=cfg.save_compact_format,
        toks_per_batch=cfg.toks_per_batch,
        batch_size=cfg.batch_size,
    )


if __name__ == "__main__":
    main()
