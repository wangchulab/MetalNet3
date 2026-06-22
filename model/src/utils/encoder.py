import os.path as osp
from pathlib import Path
from typing import Sequence, Tuple

import numpy as np
import pandas as pd
import torch
import tqdm
from Bio import SeqIO
from torch.utils.data import DataLoader, Dataset
from transformers import AutoModelForMaskedLM, AutoTokenizer


def encode_resi(
    df: pd.DataFrame,
    id2encoding: dict,
):
    if "label" in df.columns:
        df["y"] = df["label"].map(lambda x: np.array([x]))  # type: ignore
    df["x"] = df.apply(
        lambda row: id2encoding[row["seq_id"]][row["resi_seq_posi"]].numpy(), axis=1
    )
    return df


def parse_fasta_file(file: str) -> dict:

    id2seq = dict()
    for r in SeqIO.parse(osp.expanduser(file), "fasta"):
        id2seq[r.id] = str(r.seq)
    return id2seq


def from_fasta_to_encoding(
    encoder: "Encoder",
    fasta_file: str,
    struct_fasta_file: str | None = None,
) -> dict:

    id2seq = parse_fasta_file(fasta_file)
    id2struct_seq = (
        parse_fasta_file(struct_fasta_file) if struct_fasta_file is not None else None
    )
    return encoder.extract(id2seq, id2struct_seq=id2struct_seq)


def get_encoder(model: str, model_path: str, device: str) -> "Encoder":

    if model == "ankh":
        return AnkhEncoder(model_path, device)
    elif model == "esm2":
        return ESM2Encoder(model_path, device)
    elif model == "prosst":
        return ProSSTEncoder(model_path, device)
    elif model == "prott5":
        return ProtT5Encoder(model_path, device)
    elif model == "saprot":
        return SaProtEncoder(model_path, device)
    elif model == "esmc":
        model_path = Path(model_path).name  # file name for esmc
        return ESMCEncoder(model_path, device)
    else:
        raise ValueError()


class Encoder:

    def __init__(
        self,
        model_path: str,
        device: str,
        num_prefix_tok: int = 1,
        num_suffix_tok: int = 1,
    ):
        self.tokenizer = AutoTokenizer.from_pretrained(
            model_path, trust_remote_code=True
        )
        self.model = AutoModelForMaskedLM.from_pretrained(
            model_path, trust_remote_code=True
        ).to(device)
        self.device = device

        self.num_prefix_tok = num_prefix_tok
        self.num_suffix_tok = num_suffix_tok

    def _prepare(self, id2seq: dict, **kwargs) -> Tuple[DataLoader, int]:

        def collate_fn(raw_batch: Sequence[Tuple[str, str]]):
            batch_labels, seq_str_list = zip(*raw_batch)
            inputs = self.tokenizer(seq_str_list, return_tensors="pt", padding=True)
            return batch_labels, inputs

        dataset = FastaBatchedDataset(id2seq.keys(), id2seq.values())
        batches = dataset.get_batch_indices(
            # batched inference will speed up by about 1 min for metalnet dataset seqs (4.5 k)
            toks_per_batch=(
                0  # per seq a batch
                if "toks_per_batch" not in kwargs
                else kwargs["toks_per_batch"]
            ),
            extra_toks_per_seq=self.num_prefix_tok + self.num_suffix_tok,
        )
        dataloader = DataLoader(
            dataset=dataset,
            collate_fn=collate_fn,
            batch_sampler=batches,  # type: ignore
        )

        return dataloader, len(batches)

    def extract(self, id2seq: dict, **kwargs) -> dict:

        id2encoding = dict()
        dataloader, num_batches = self._prepare(id2seq, **kwargs)
        with torch.no_grad():
            for _, (labels, inputs) in tqdm.tqdm(
                enumerate(dataloader), total=num_batches
            ):
                inputs = {k: v.to(self.device) for k, v in inputs.items()}
                outputs = self.model(**inputs, output_hidden_states=True)
                hidden_states = (
                    outputs.hidden_states[-1][
                        :, self.num_prefix_tok : -self.num_suffix_tok, :
                    ]
                    .detach()
                    .cpu()
                )
                for idx, label in enumerate(labels):
                    id2encoding[label] = hidden_states[idx].clone()

        return id2encoding


class ESM2Encoder(Encoder):

    pass


class AnkhEncoder(Encoder):

    def __init__(
        self,
        model_path: str,
        device: str,
        num_prefix_tok: int = 0,
        num_suffix_tok: int = 1,
    ):
        from transformers import T5EncoderModel

        self.model = T5EncoderModel.from_pretrained(model_path).to(device)  # type: ignore
        self.tokenizer = AutoTokenizer.from_pretrained(model_path)
        self.device = device
        self.num_prefix_tok = num_prefix_tok
        self.num_suffix_tok = num_suffix_tok


class ProtT5Encoder(Encoder):

    def __init__(
        self,
        model_path: str,
        device: str,
        num_prefix_tok: int = 0,
        num_suffix_tok: int = 1,
    ):
        from transformers import T5EncoderModel, T5Tokenizer

        self.model = T5EncoderModel.from_pretrained(model_path).to(device)  # type: ignore
        self.tokenizer = T5Tokenizer.from_pretrained(model_path, do_lower_case=False)
        self.device = device
        self.num_prefix_tok = num_prefix_tok
        self.num_suffix_tok = num_suffix_tok

    def extract(self, id2seq: dict, **kwargs) -> dict:
        import re

        id2seq = {
            id: re.sub(r"[UZOB]", "X", " ".join(list(seq)))
            for id, seq in id2seq.items()
        }

        return super().extract(id2seq, **kwargs)


class SaProtEncoder(Encoder):

    def extract(self, id2seq: dict, **kwargs) -> dict:

        id2struct_seq = kwargs["id2struct_seq"]
        id2seq_merged = dict()
        for id in id2seq.keys():
            seq = id2seq[id]
            struct_seq = id2struct_seq[id]
            merged_seq = "".join(a + b for a, b in zip(seq, struct_seq))
            id2seq_merged[id] = merged_seq

        return super().extract(id2seq_merged, **kwargs)


class ProSSTEncoder(Encoder):

    def extract(self, id2seq: dict, **kwargs) -> dict:

        # NOTE: The original code does not provide how to padding structure ids when dealing with
        # sequences with different length, see:
        # https://github.com/ai4protein/ProSST/blob/main/zero_shot/proteingym_benchmark.py
        # So we do not provide code for batched inference.

        id2struct_seq = kwargs["id2struct_seq"]

        id2encoding = dict()
        keys = list(id2seq.keys())

        with torch.no_grad():
            for id in tqdm.tqdm(keys):
                seq = id2seq[id]
                struct_seq = id2struct_seq[id]

                struct_seq = [int(i) for i in struct_seq.split(",")]
                ss_input_ids = ProSSTEncoder.tokenize_structure_sequence(struct_seq).to(
                    self.device
                )
                tokenized_results = self.tokenizer([seq], return_tensors="pt")
                input_ids = tokenized_results["input_ids"].to(self.device)
                attention_mask = tokenized_results["attention_mask"].to(self.device)

                outputs = self.model(
                    input_ids=input_ids,
                    attention_mask=attention_mask,
                    ss_input_ids=ss_input_ids,
                    labels=input_ids,
                    output_hidden_states=True,
                )

                id2encoding[id] = (
                    outputs.hidden_states[-1][0][
                        self.num_prefix_tok : -self.num_suffix_tok
                    ]
                    .detach()
                    .cpu()
                )

        return id2encoding

    @staticmethod
    def tokenize_structure_sequence(structure_sequence):
        shift_structure_sequence = [i + 3 for i in structure_sequence]
        shift_structure_sequence = [1, *shift_structure_sequence, 2]
        return torch.tensor(
            [
                shift_structure_sequence,
            ],
            dtype=torch.long,
        )


class ESMCEncoder(Encoder):

    def __init__(self, model_path, device, num_prefix_tok=1, num_suffix_tok=1):
        from esm.models.esmc import ESMC

        self.model = ESMC.from_pretrained(model_path).to(device)
        self.device = device
        self.num_prefix_tok = num_prefix_tok
        self.num_suffix_tok = num_suffix_tok

    def extract(self, id2seq, **kwargs):
        from esm.sdk.api import ESMProtein, LogitsConfig

        id2encoding = dict()

        for k, v in tqdm.tqdm(id2seq.items()):
            protein_tensor = self.model.encode(ESMProtein(sequence=v))
            logits_output = self.model.logits(
                protein_tensor, LogitsConfig(sequence=True, return_embeddings=True)
            )
            id2encoding[k] = (
                logits_output.embeddings[0][self.num_prefix_tok : -self.num_suffix_tok]
                .detach()
                .cpu()
            )

        return id2encoding


class FastaBatchedDataset(Dataset):
    """Refers to https://github.com/facebookresearch/esm/blob/main/esm/data.py"""

    def __init__(self, sequence_labels, sequence_strs):
        self.sequence_labels = list(sequence_labels)
        self.sequence_strs = list(sequence_strs)

    def __len__(self):
        return len(self.sequence_labels)

    def __getitem__(self, idx):
        return self.sequence_labels[idx], self.sequence_strs[idx]

    def get_batch_indices(self, toks_per_batch, extra_toks_per_seq=0):
        sizes = [(len(s), i) for i, s in enumerate(self.sequence_strs)]
        sizes.sort()
        batches = []
        buf = []
        max_len = 0

        def _flush_current_buf():
            nonlocal max_len, buf
            if len(buf) == 0:
                return
            batches.append(buf)
            buf = []
            max_len = 0

        for sz, i in sizes:
            sz += extra_toks_per_seq
            if max(sz, max_len) * (len(buf) + 1) > toks_per_batch:
                _flush_current_buf()
            max_len = max(max_len, sz)
            buf.append(i)

        _flush_current_buf()
        return batches
