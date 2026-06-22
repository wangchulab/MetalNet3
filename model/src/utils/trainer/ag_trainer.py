from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd
from autogluon.tabular import TabularPredictor
from numpy import ndarray

from . import ProblemType, Trainer


class AgTrainer(Trainer):

    def __init__(self, problem_type: ProblemType, save_dir: str) -> None:
        super().__init__(problem_type, save_dir)

        if self.problem_type == ProblemType.binary:
            self.eval_metric = "f1"
        elif self.problem_type == ProblemType.multiclass:
            self.eval_metric = "f1_macro"

    def train(self, df_train: pd.DataFrame, df_tune: pd.DataFrame, **kwargs) -> Any:
        train_data_df = pd.DataFrame(np.stack(df_train["x"]))  # type: ignore
        tuning_data_df = pd.DataFrame(np.stack(df_tune["x"]))  # type: ignore
        train_data_df["y"] = np.stack(df_train["y"]).flatten().tolist()  # type: ignore
        tuning_data_df["y"] = np.stack(df_tune["y"]).flatten().tolist()  # type: ignore

        cur_save_dir = Path(self.save_dir) / "AutogluonModels"
        version = kwargs["version"] if "version" in kwargs.keys() else None
        cur_save_dir = (
            cur_save_dir / str(version) if version is not None else cur_save_dir
        )

        predictor = TabularPredictor(
            label="y",
            problem_type=self.problem_type.value,
            eval_metric=self.eval_metric,
            path=cur_save_dir,
            verbosity=1,
        ).fit(
            train_data_df,
            tuning_data=tuning_data_df,
            presets="best_quality",
            use_bag_holdout=True,
        )
        return predictor

    def predict(
        self, model: TabularPredictor, df_predict: pd.DataFrame, **kwargs
    ) -> ndarray:
        return model.predict_proba(
            pd.DataFrame(np.stack(df_predict["x"])), as_pandas=False  # type: ignore
        )

    def tune(
        self,
        df_train: pd.DataFrame,
        df_valid: pd.DataFrame,
        output_dict: bool = True,
        version: int | None = None,
        **kwargs
    ):
        df_train, df_tune = self.split_train_test(
            df=df_train, id=["seq_id"], test_size=0.1
        )

        model = self.train(df_train, df_tune, version=version, **kwargs)
        extra_params = {}
        if self.problem_type == ProblemType.binary:
            y_pred = self.predict(model, df_tune)[:, 1].reshape(-1, 1)
            threshold, _ = self.search_threshold_for_binary_f1(
                y_pred=y_pred,
                y_true=np.stack(df_tune["y"]),  # type: ignore
            )
            extra_params["threshold"] = threshold

        result = self.test(model, df_valid, output_dict, **extra_params)

        return model, result

    def load_model(self, model_path: str) -> Any:
        path = model_path
        assert Path(model_path).is_dir()
        if (Path(model_path) / "AutogluonModels").exists():
            path = Path(model_path) / "AutogluonModels"
        return TabularPredictor.load(path)  # type: ignore
