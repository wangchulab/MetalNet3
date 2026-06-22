import os
import pickle
from pathlib import Path
from typing import Any

import cupy as cp
import numpy as np
import optuna
import pandas as pd
from cuml.svm import SVC

from . import ProblemType, Trainer


class SVMTrainer(Trainer):

    def train(self, df_train: pd.DataFrame, df_tune: pd.DataFrame, **kwargs) -> Any:

        cur_save_dir = Path(self.save_dir) / "SVMModel"
        version = kwargs["version"] if "version" in kwargs.keys() else None
        cur_save_dir = (
            cur_save_dir / str(version) if version is not None else cur_save_dir
        )
        os.makedirs(cur_save_dir, exist_ok=True)

        x_train = self.from_series_to_cp_array(df_train["x"])
        y_train = self.from_series_to_cp_array(df_train["y"])
        model = self._train_impl(x_train, y_train, **kwargs["study_params"])

        pickle.dump(model, open(Path(cur_save_dir) / "model.pkl", "wb"))

        return model

    def predict(self, model: Any, df_predict: pd.DataFrame, **kwargs) -> np.ndarray:
        batch_size = (
            len(df_predict) if "batch_size" not in kwargs else kwargs["batch_size"]
        )
        y_pred_proba_list = []
        for i in range(0, len(df_predict), batch_size):
            batch_df = df_predict.iloc[i : i + batch_size]
            batch_x_pred = self.from_series_to_cp_array(batch_df["x"])
            batch_y_pred_proba = model.predict_proba(batch_x_pred)
            y_pred_proba_list.append(cp.asnumpy(batch_y_pred_proba))
        y_pred_proba = np.concatenate(y_pred_proba_list, axis=0)
        return y_pred_proba

    def tune(
        self,
        df_train: pd.DataFrame,
        df_valid: pd.DataFrame,
        output_dict: bool = True,
        version: int | None = None,
        **kwargs,
    ):
        df_train, df_tune = self.split_train_test(df_train, ["seq_id"], 0.1)
        study = self._tune_impl(df_train, df_tune)

        model = self.train(
            df_train, df_tune, version=version, study_params=study.best_params, **kwargs
        )
        result = self.test(model, df_valid, output_dict, **study.best_trial.user_attrs)

        return model, result

    def load_model(self, model_path: str) -> Any:
        model_file = model_path
        if Path(model_path).is_dir():
            if (Path(model_path) / "model.pkl").exists():
                model_file = Path(model_path) / "model.pkl"
        return pickle.load(open(model_file, "rb"))

    def _train_impl(
        self,
        x_train: cp.ndarray,
        y_train: cp.ndarray,
        **kwargs,
    ):
        model = SVC(kernel="rbf", **kwargs, probability=True)
        model.fit(x_train, y_train.flatten())
        return model

    def _tune_impl(
        self,
        df_train: pd.DataFrame,
        df_tune: pd.DataFrame,
    ) -> optuna.Study:
        study = optuna.create_study(
            sampler=optuna.samplers.TPESampler(),
            study_name="f1_tpe_svm",
            direction="maximize",
        )

        x_train, y_train = self.from_series_to_cp_array(
            df_train["x"]
        ), self.from_series_to_cp_array(df_train["y"])
        x_tune, y_tune = self.from_series_to_cp_array(
            df_tune["x"]
        ), self.from_series_to_cp_array(df_tune["y"])

        study.optimize(
            lambda trail: self._objective(trail, x_train, y_train, x_tune, y_tune),
            n_trials=20,
            catch=(RuntimeError,),
            gc_after_trial=True,
        )

        return study

    def _objective(
        self,
        trial: optuna.Trial,
        x_train: cp.ndarray,
        y_train: cp.ndarray,
        x_tune: cp.ndarray,
        y_tune: cp.ndarray,
    ) -> float:
        from sklearn.metrics import f1_score

        C = trial.suggest_float("C", 0.01, 100.0, log=True)

        model = self._train_impl(x_train, y_train, C=C)

        if self.problem_type == ProblemType.binary:
            y_pred_proba = model.predict_proba(x_tune)[:, 1].reshape(-1, 1)
            threshold, score = self.search_threshold_for_binary_f1(
                cp.asnumpy(y_pred_proba), cp.asnumpy(y_tune)
            )
            trial.set_user_attr("threshold", threshold)
        elif self.problem_type == ProblemType.multiclass:
            y_pred_label = cp.argmax(model.predict_proba(x_tune), axis=-1)
            score: float = f1_score(
                y_pred=cp.asnumpy(y_pred_label),
                y_true=cp.asnumpy(y_tune),
                average="macro",
            )  # type: ignore
        else:
            raise ValueError
        return score

    @staticmethod
    def from_series_to_cp_array(s: pd.Series):
        return cp.array(np.stack(s.tolist()))
