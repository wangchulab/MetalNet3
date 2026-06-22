import torch
import torch.nn.functional as F


def cross_entropy_loss(
    input: torch.Tensor,
    target: torch.Tensor,
    weight: torch.Tensor | None = None,
    gamma: float = 0.0,
) -> torch.Tensor:
    """A combined cross entropy loss for multiclass clf

    Args:
        input (torch.Tensor): (N, C)
        target (torch.Tensor): (N,)
        weight (torch.Tensor | None, optional): (C,) or None. Defaults to None.
        gamma (float, optional): focal loss gamma. Defaults to 0.0.
    """

    weight = (
        torch.ones(input.shape[-1]).to(input.device)
        if weight is None
        else weight.to(input.device)
    )

    log_prob = F.log_softmax(input, dim=-1)
    log_prob = torch.gather(log_prob, 1, target.unsqueeze(-1)).flatten()  # (n,)
    prob = torch.exp(log_prob)

    ce_loss = -log_prob
    weights = weight[target]  # (n,)
    ce_loss = weights * (1 - prob) ** gamma * ce_loss

    return ce_loss.sum() / weights.sum()  # mean reduction
