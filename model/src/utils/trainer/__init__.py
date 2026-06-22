import enum
import random
from abc import abstractmethod
from typing import Any, List, Tuple

import numpy as np
import pandas as pd
from omegaconf import DictConfig
from sklearn.metrics import classification_report, f1_score


def get_trainer(
    model: DictConfig,
    problem_type: str,
    save_dir: str,
    **kwargs,
) -> "Trainer":
    problem_type = ProblemType.from_text(problem_type)

    if model.name == "svm":
        from .svm_trainer import SVMTrainer

        return SVMTrainer(problem_type, save_dir)
    elif model.name == "ag":
        from .ag_trainer import AgTrainer

        return AgTrainer(problem_type, save_dir)
    elif model.name == "nn":
        from .nn_trainer import MetalMLPConfig, NNTrainer

        return NNTrainer(
            problem_type,
            save_dir,
            cfg=MetalMLPConfig.from_hydra_dict(
                nn=model,
                problem_type=problem_type,
                cuda=int(kwargs["device"].removeprefix("cuda:")),
            ),
        )
    else:
        raise ValueError


class ProblemType(enum.Enum):

    binary = "binary"
    multiclass = "multiclass"

    @classmethod
    def from_text(cls, text: str):
        for lang in cls:
            lang: ProblemType
            if lang.value == text:
                return lang
        raise ValueError(f"No problem type matched to {text}.")


class Trainer:

    def __init__(self, problem_type: ProblemType, save_dir: str) -> None:
        self.problem_type = problem_type
        self.save_dir = save_dir

    @abstractmethod
    def train(self, df_train: pd.DataFrame, df_tune: pd.DataFrame, **kwargs) -> Any:
        raise NotImplementedError

    def test(
        self,
        model: Any,
        df_test: pd.DataFrame,
        output_dict: bool,
        **kwargs,
    ):
        y_true = np.stack(df_test["y"])  # type: ignore

        y_pred = self.predict(model, df_test, **kwargs)
        if self.problem_type == ProblemType.binary:
            y_pred = y_pred[:, 1].reshape(-1, 1)
            threshold = kwargs["threshold"]
            y_pred_label = np.where(y_pred >= threshold, 1, 0)
        elif self.problem_type == ProblemType.multiclass:
            y_pred_label = np.argmax(y_pred, axis=-1)
        else:
            raise ValueError

        return classification_report(
            y_true, y_pred_label, digits=4, output_dict=output_dict
        )

    @abstractmethod
    def predict(
        self,
        model: Any,
        df_predict: pd.DataFrame,
        **kwargs,
    ) -> np.ndarray:
        """Should return a array shaped as (n, num_type)"""
        raise NotImplementedError

    @abstractmethod
    def tune(
        self,
        df_train: pd.DataFrame,
        df_valid: pd.DataFrame,
        output_dict: bool = True,
        version: int | None = None,
        **kwargs,
    ):
        """Tune stage. Should return model and tune report"""
        raise NotImplementedError

    @abstractmethod
    def load_model(self, model_path: str) -> Any:
        raise NotImplementedError

    def tune_loop(
        self,
        df: pd.DataFrame,
        **kwargs,
    ):
        results = []
        for idx in range(3):
            df_train, df_valid = self.split_train_test(df, ["seq_id"], 0.1)
            _, result = self.tune(df_train, df_valid, version=idx, **kwargs)
            results.append(pd.DataFrame(result).T)

        df_report = (
            pd.concat(results, keys=range(len(results)), names=["report", "label"])
            .groupby("label")
            .agg(["mean", "var"])
        )
        return df_report

    @staticmethod
    def split_train_test(
        df: pd.DataFrame,
        id: List[str],
        test_size: float,
    ) -> Tuple[pd.DataFrame, pd.DataFrame]:
        chains = sorted(list(set(zip(*[df[c] for c in id]))))
        random.shuffle(chains)
        test_size = int(len(chains) * test_size)
        test_chains = set(chains[:test_size])

        df_output = df.copy(deep=True)
        df_test = df_output[
            df_output.apply(
                lambda row: tuple([row[c] for c in id]) in test_chains, axis=1
            )
        ]
        df_train = df_output[
            df_output.apply(
                lambda row: tuple([row[c] for c in id]) not in test_chains, axis=1
            )
        ]
        return df_train, df_test

    @staticmethod
    def search_threshold_for_binary_f1(
        y_pred: np.ndarray,
        y_true: np.ndarray,
    ) -> Tuple[float, float]:
        assert y_pred.shape == (
            y_pred.shape[0],
            1,
        ), f"should be (n, 1), given shape is {y_pred.shape}"
        assert y_true.shape == (
            y_true.shape[0],
            1,
        ), f"should be (n, 1), given shape is {y_true.shape}"

        max_score = 0.0
        threshold = 0.0
        for i in np.arange(0, 1, 0.1):
            y_pred_label = np.where(y_pred >= i, 1, 0)
            score = f1_score(y_true, y_pred_label)
            if score > max_score:
                threshold = i
                max_score = score

        return threshold, max_score  # type: ignore
