from dataclasses import asdict

import lightning as L
import torch
from lightning.pytorch.utilities.types import EVAL_DATALOADERS
from sklearn.metrics import classification_report
from torch.optim.lr_scheduler import ReduceLROnPlateau

from .. import ProblemType
from .cfg import MetalMLPConfig
from .loss import cross_entropy_loss
from .model import MetalMLP


class MetalMLPPL(L.LightningModule):

    def __init__(
        self,
        cfg: MetalMLPConfig,
        ce_loss_weights: torch.Tensor | None = None,
    ) -> None:
        super().__init__()
        self.save_hyperparameters(asdict(cfg))
        self.cfg = cfg
        self.model = MetalMLP(
            output_dim=cfg.num_labels,
            hidden_dims=cfg.hidden_dims,
            dropout=cfg.dropout,
        )
        self.ce_loss_weights = ce_loss_weights

    def training_step(self, batch: tuple):
        x, y = batch
        logits = self.forward(x)
        loss = self.calc_loss(logits, y)
        self.log_dict({"training_loss": loss.item()})
        return loss

    def on_validation_epoch_start(self) -> None:
        self.valid_epoch_output = []

    def validation_step(self, batch: tuple):
        x, y = batch
        logits = self.forward(x)
        output = {"logits": logits, "label": y}
        self.valid_epoch_output.append(output)

    def predict_step(self, x: list) -> EVAL_DATALOADERS:
        return super().predict_step(x[0])  # why x become a list?

    def on_validation_epoch_end(self) -> None:
        output = self.valid_epoch_output.copy()
        self.valid_epoch_output.clear()

        logits = torch.concat([i["logits"] for i in output])
        label = torch.concat([i["label"] for i in output])
        loss = self.calc_loss(logits, label)
        metrics = self.compute_metrics(logits, label)

        self.log_dict({"validation_loss": loss.item()})
        for k, v in metrics.items():
            self.log_dict({f"validation_{k}": v})

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.model.forward(x)

    def calc_loss(self, logits, label) -> torch.Tensor:
        loss = cross_entropy_loss(
            logits, label, weight=self.ce_loss_weights, gamma=self.cfg.focal_loss_gamma
        )
        return loss

    def compute_metrics(
        self,
        logits: torch.Tensor,
        label: torch.Tensor,
    ) -> dict:

        label = label.cpu().numpy()
        pred_label = torch.softmax(logits, dim=-1).argmax(dim=-1).cpu().numpy()
        report = classification_report(label, pred_label, output_dict=True)
        if self.cfg.problem_type == ProblemType.binary:
            metrics = {
                "f1-score": report["1"]["f1-score"],  # type: ignore
                "precision": report["1"]["precision"],  # type: ignore
                "recall": report["1"]["recall"],  # type: ignore
            }
        elif self.cfg.problem_type == ProblemType.multiclass:
            metrics = {
                "f1-score": report["macro avg"]["f1-score"],  # type: ignore
                "accuracy": report["accuracy"],  # type: ignore
            }

        return metrics

    def configure_optimizers(self):
        optimizer = torch.optim.Adam(
            self.parameters(),
            lr=self.cfg.learning_rate,
            weight_decay=self.cfg.weight_decay,
        )
        scheduler = ReduceLROnPlateau(
            optimizer=optimizer,
            mode=self.cfg.eval_metric_mode,
        )
        return {
            "optimizer": optimizer,
            "lr_scheduler": {
                "scheduler": scheduler,
                "monitor": f"validation_{self.cfg.eval_metric}",
                "interval": "epoch",
                "frequency": 1,
            },
        }
