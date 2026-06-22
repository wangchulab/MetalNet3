from typing import Optional

import lightning as L
import numpy as np
import pandas as pd
import torch
from torch.utils.data.dataloader import DataLoader
from torch.utils.data.dataset import TensorDataset
from torch.utils.data.sampler import Sampler, WeightedRandomSampler

from .cfg import MetalMLPConfig


class MetalResiData(L.LightningDataModule):

    def __init__(
        self,
        cfg: MetalMLPConfig,
        df_train: pd.DataFrame | None = None,
        df_valid: pd.DataFrame | None = None,
        df_test: pd.DataFrame | None = None,
        df_predict: pd.DataFrame | None = None,
    ) -> None:
        super().__init__()
        self.cfg = cfg

        self.df_train = df_train
        self.df_valid = df_valid
        self.df_test = df_test
        self.df_predict = df_predict

    def train_dataloader(self):
        assert self.df_train is not None
        sampler = None
        shuffle = True
        if self.cfg.use_weighted_sampler:
            weights = self.calc_weights(self.df_train)
            y = torch.from_numpy(np.concatenate(self.df_train["y"].tolist())).flatten()
            sampler = WeightedRandomSampler(weights[y], len(y), True)  # type: ignore
            shuffle = False
        return self.__create_dataloader(
            self.df_train, self.cfg.train_batch_size, shuffle, sampler
        )

    def val_dataloader(self):
        assert self.df_valid is not None
        return self.__create_dataloader(self.df_valid, self.cfg.valid_batch_size, False)

    def test_dataloader(self):
        assert self.df_test is not None
        return self.__create_dataloader(self.df_test, self.cfg.valid_batch_size, False)

    def predict_dataloader(self):
        assert self.df_predict is not None
        return self.__create_dataloader(
            self.df_predict, self.cfg.valid_batch_size, False
        )

    @staticmethod
    def __create_dataloader(
        df: pd.DataFrame,
        batch_size: int,
        shuffle: bool,
        sampler: Optional[Sampler] = None,
    ):
        x = torch.from_numpy(np.stack(df["x"].tolist()))
        y = (
            torch.from_numpy(np.concatenate(df["y"].tolist()))
            if "y" in df.columns
            else None
        )
        dataset = TensorDataset(x, y) if y is not None else TensorDataset(x)

        return DataLoader(
            dataset,
            batch_size=batch_size,
            shuffle=shuffle,
            sampler=sampler,
            num_workers=4,
            multiprocessing_context="fork",  # work with joblib
        )

    @staticmethod
    def calc_weights(
        df: pd.DataFrame,
    ) -> torch.Tensor:
        y = torch.from_numpy(np.concatenate(df["y"].tolist())).flatten()
        counts = torch.bincount(y)
        weight = counts.sum() / counts

        return weight.nan_to_num(posinf=0.0)
