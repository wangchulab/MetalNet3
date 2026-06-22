from dataclasses import dataclass, field

from omegaconf import DictConfig

from .. import ProblemType


@dataclass
class MetalMLPConfig:

    problem_type: ProblemType

    # data config
    train_batch_size: int
    valid_batch_size: int

    # trainer config
    cuda: int
    num_epochs: int
    patience: int
    learning_rate: float
    weight_decay: float
    use_weighted_sampler: bool
    use_ce_loss_weights: bool
    focal_loss_gamma: float
    eval_metric: str = "f1-score"
    eval_metric_mode: str = "max"

    # model config
    hidden_dims: list = field(default_factory=list)
    num_labels: int = 2
    dropout: float = 0.2

    @classmethod
    def from_hydra_dict(cls, nn: DictConfig, cuda: int, problem_type: ProblemType):
        num_hidden_layers = nn.num_hidden_layers
        hidden_dim = nn.hidden_dim
        hidden_dims = [] if num_hidden_layers == 0 else [hidden_dim] * num_hidden_layers

        return cls(
            problem_type=problem_type,
            train_batch_size=nn.batch_size.train,
            valid_batch_size=nn.batch_size.valid,
            cuda=cuda,
            num_epochs=nn.num_epochs,
            patience=nn.patience,
            learning_rate=nn.learning_rate,
            weight_decay=nn.weight_decay,
            use_weighted_sampler=nn.use_weighted_sampler,
            use_ce_loss_weights=nn.use_ce_loss_weights,
            focal_loss_gamma=nn.focal_loss_gamma,
            eval_metric=nn.eval_metric,
            eval_metric_mode=nn.eval_metric_mode,
            hidden_dims=hidden_dims,
            dropout=nn.dropout,
            num_labels=nn.num_labels,
        )
