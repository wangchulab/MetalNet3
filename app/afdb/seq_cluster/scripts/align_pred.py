import subprocess
import traceback
from io import StringIO
from pathlib import Path
from typing import List

import pandas as pd
import tqdm
from absl import app, flags, logging
from Bio import AlignIO, SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord

CLUSTALO_EXE = Path("~/install/clustalo/clustalo-1.2.4-Ubuntu-x86_64").expanduser()


def setup_arguments():
    flags.DEFINE_string("fasta_file", None, required=True, help="")
    flags.DEFINE_string(
        "cluster_file",
        None,
        required=True,
        help="cluster file from mmseqs, repr to member",
    )
    flags.DEFINE_string("pred_file", None, required=True, help="")
    flags.DEFINE_string("result_file", None, required=True, help="")


def get_aln_from_seqs(
    id_to_seqs: dict,
    clustalo_exe: str = str(CLUSTALO_EXE),
) -> List[SeqRecord]:
    fasta_fmt = ""
    for seq_id, seq in id_to_seqs.items():
        fasta_fmt += f">{seq_id}\n{seq}\n"

    command = [clustalo_exe, "--in", "-", "--outfmt=fasta", "--threads=20"]

    process = subprocess.Popen(
        command,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    stdout, _ = process.communicate(input=fasta_fmt)

    alignment_output = StringIO(stdout)
    alignment = AlignIO.read(alignment_output, "fasta")

    return list(alignment)


def real_posi_to_aligned_posi(seq: str):
    result = dict()
    real_posi = -1
    for idx, aa in enumerate(seq):
        if aa != "-":
            real_posi += 1
            result[real_posi] = idx

    return result


def main(argv):

    FLAGS = flags.FLAGS
    fasta_file = FLAGS.fasta_file
    cluster_file = FLAGS.cluster_file
    pred_file = FLAGS.pred_file
    result_file = FLAGS.result_file

    # handle input
    logging.info("Loading inputs...")
    id_to_seq = dict()
    for r in SeqIO.parse(fasta_file, "fasta"):
        id_to_seq[r.id.split("-")[1]] = str(r.seq)

    repr_to_memebers = dict()
    df = pd.read_table(cluster_file, header=None)
    for (repr,), df_repr in df.groupby(by=[0]):
        repr_to_memebers[repr] = set(df_repr[1])
    del df

    id_to_pred = dict()
    df = pd.read_table(pred_file)
    for _, row in df.iterrows():
        id_to_pred[row["seq_id"].split("-")[1]] = set(
            [int(i) for i in row["posi"].split(",")]
        )
    del df
    logging.info("Done.")

    # align result
    id_to_align_result = []
    for repr, members in tqdm.tqdm(repr_to_memebers.items()):

        member_ids_to_seqs = dict()
        for member in members:
            member_ids_to_seqs[member] = id_to_seq[member]

        # get alignments
        if len(member_ids_to_seqs) == 1:
            alignments = [SeqRecord(seq=Seq(id_to_seq[repr]), id=repr, description="")]
        else:
            try:
                alignments = get_aln_from_seqs(member_ids_to_seqs)
            except:
                traceback.print_exc()
                logging.error(f"Falied in {repr}.")
                continue

        # first collect all pred aligned posis
        all_pred_aligned_posis = set()
        for r in alignments:
            r: SeqRecord
            if r.id in id_to_pred:
                seq = str(r.seq)
                real_to_aligned = real_posi_to_aligned_posi(seq)
                real_pred_posis = id_to_pred[r.id]
                for p in real_pred_posis:
                    aligned_posi = real_to_aligned[p]
                    all_pred_aligned_posis.add(aligned_posi)

        # then check each seq in the aligned positions
        all_pred_aligned_posis = sorted(list(all_pred_aligned_posis))
        for r in alignments:
            seq = str(r.seq)
            real_to_aligned = real_posi_to_aligned_posi(seq)
            aligned_to_real = dict(
                zip(real_to_aligned.values(), real_to_aligned.keys())
            )
            real_pred_posis = id_to_pred[r.id] if r.id in id_to_pred else set()

            real_posis = []
            real_aas = []
            aligned_posis = []
            is_preds = []
            for p in all_pred_aligned_posis:
                real_posi = -1 if p not in aligned_to_real else aligned_to_real[p]
                real_aa = "-" if p not in aligned_to_real else seq[p]
                aligned_posi = -1 if p not in aligned_to_real else p
                is_pred = 0 if real_posi not in real_pred_posis else 1

                real_posis.append(real_posi)
                real_aas.append(real_aa)
                aligned_posis.append(aligned_posi)
                is_preds.append(is_pred)

            id_to_align_result.append(
                {
                    "seq_id": r.id,
                    "real_posi": ",".join([str(i) for i in real_posis]),
                    "real_aa": ",".join(real_aas),
                    "algined_posi": ",".join([str(i) for i in aligned_posis]),
                    "is_pred": ",".join([str(i) for i in is_preds]),
                    "rep_id": repr,
                }
            )

    pd.DataFrame(id_to_align_result).to_csv(result_file, sep="\t", index=None)  # type: ignore


if __name__ == "__main__":
    setup_arguments()
    app.run(main)
