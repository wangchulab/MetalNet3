from pathlib import Path
from typing import Any

import lightning as L
import numpy as np
from lightning.pytorch.callbacks.early_stopping import EarlyStopping
from lightning.pytorch.callbacks.model_checkpoint import ModelCheckpoint
from lightning.pytorch.loggers import CSVLogger
from pandas import DataFrame

from .. import ProblemType, Trainer
from .cfg import MetalMLPConfig
from .data import MetalResiData
from .model_pl import MetalMLPPL


class NNTrainer(Trainer):

    def __init__(self, problem_type: str, save_dir: str, cfg: MetalMLPConfig) -> None:
        super().__init__(problem_type, save_dir)
        self.cfg = cfg

    def train(self, df_train: DataFrame, df_tune: DataFrame, **kwargs) -> Any:
        version = kwargs["version"] if "version" in kwargs.keys() else None

        data = MetalResiData(self.cfg, df_train=df_train, df_valid=df_tune)
        ce_loss_weights = (
            None
            if not self.cfg.use_ce_loss_weights
            else MetalResiData.calc_weights(df_train).to(f"cuda:{self.cfg.cuda}")
        )
        model = MetalMLPPL(self.cfg, ce_loss_weights=ce_loss_weights)
        trainer = L.Trainer(
            devices=[self.cfg.cuda],
            max_epochs=self.cfg.num_epochs,
            logger=[CSVLogger(save_dir=self.save_dir, version=version)],
            callbacks=[
                EarlyStopping(
                    monitor=f"validation_{self.cfg.eval_metric}",
                    patience=self.cfg.patience,
                    mode=self.cfg.eval_metric_mode,
                ),
                ModelCheckpoint(
                    monitor=f"validation_{self.cfg.eval_metric}",
                    mode=self.cfg.eval_metric_mode,
                ),
            ],
        )

        trainer.fit(model, data)
        best_model = self.load_model(trainer.checkpoint_callback.best_model_path)

        return best_model

    def tune(
        self,
        df_train: DataFrame,
        df_valid: DataFrame,
        output_dict: bool = True,
        version: int | None = None,
        **kwargs,
    ):
        df_train, df_tune = self.split_train_test(
            df=df_train, id=["seq_id"], test_size=0.1
        )
        model = self.train(df_train, df_tune, version=version)

        extra_params = {}
        if self.problem_type == ProblemType.binary:
            y_pred = self.predict(model, df_tune)[:, 1].reshape(-1, 1)
            threshold, _ = self.search_threshold_for_binary_f1(
                y_pred=y_pred, y_true=np.stack(df_tune["y"])  # type: ignore
            )
            extra_params["threshold"] = threshold

        result = self.test(model, df_valid, output_dict, **extra_params)

        return model, result

    def predict(self, model: Any, df_predict: DataFrame, **kwargs) -> np.ndarray:
        trainer = L.Trainer(devices=[self.cfg.cuda], logger=False)
        data = MetalResiData(self.cfg, df_predict=df_predict)
        preds = trainer.predict(model, data)
        preds = [i for j in preds for i in j]  # type: ignore
        return np.array(preds)

    def load_model(self, model_path: str) -> Any:
        path = model_path
        if Path(model_path).is_dir():
            path = list(Path(model_path).glob("*ckpt"))[0]
        return MetalMLPPL.load_from_checkpoint(path, cfg=self.cfg)
