from typing import List

import torch
import torch.nn as nn


class MLP(nn.Module):

    def __init__(
        self,
        dims: List[int],
        activation: nn.Module = nn.GELU,  # type: ignore
        dropout: float = 0.2,
    ) -> None:
        super().__init__()
        assert len(dims) >= 2, "At least two dims: one hidden dim and one output dim."

        layers = []
        for hidden_dim in dims[:-1]:
            layers.append(nn.LazyLinear(hidden_dim))
            layers.append(activation())
            layers.append(nn.Dropout(dropout))
        layers.append(nn.LazyLinear(dims[-1]))  # output layer
        self.mlp = nn.Sequential(*layers)

    def forward(
        self,
        x: torch.Tensor,
    ):
        return self.mlp(x)


class MetalMLP(nn.Module):

    def __init__(
        self,
        output_dim: int,
        hidden_dims: List[int],
        dropout: float = 0.2,
    ) -> None:
        super().__init__()

        if len(hidden_dims) == 0:
            self.out = nn.LazyLinear(output_dim)
        elif len(hidden_dims) == 1:
            self.out = MLP([hidden_dims[0], output_dim], dropout=dropout)
        else:
            self.out = nn.Sequential(
                MLP(hidden_dims, dropout=dropout), nn.LazyLinear(output_dim)
            )

    def forward(
        self,
        x: torch.Tensor,
    ) -> torch.Tensor:
        return self.out(x)
