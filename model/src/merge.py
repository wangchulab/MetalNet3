from pathlib import Path

import pandas as pd
from absl import app, flags


def setup_args():
    flags.DEFINE_string(
        "p_path",
        None,
        required=True,
        help="path (dir or file) of metal prediction result",
    )
    flags.DEFINE_string(
        "tp_path", None, required=True, help="path of type prediction result"
    )
    flags.DEFINE_string(
        "gtp_path",
        None,
        required=True,
        help="path of metal group type prediction result",
    )
    flags.DEFINE_string("output_file", None, required=True, help="")


def merge_files(path: str) -> pd.DataFrame:

    p = Path(path)
    if p.is_dir():
        dfs = []
        for f in p.iterdir():
            if f.is_file():
                dfs.append(pd.read_table(f))
        return pd.concat(dfs)

    elif p.is_file():
        return pd.read_table(p)

    else:
        raise ValueError


def merge_and_reformat_preds(
    df_p: pd.DataFrame,
    df_tp: pd.DataFrame,
    df_gtp: pd.DataFrame,
) -> pd.DataFrame:
    df_p.rename(columns={"pred": "pred_proba"}, inplace=True)
    df_tp.rename(columns={"pred": "pred_type", "posi": "all_ched_posi"}, inplace=True)
    df_gtp.rename(
        columns={"pred": "pred_group_type", "posi": "all_ched_posi_"}, inplace=True
    )
    df = pd.merge(df_p, df_tp, on="seq_id")
    df = pd.merge(df, df_gtp, on="seq_id")

    records = []
    for _, row in df.iterrows():
        seq_id = row["seq_id"]
        positions = row["posi"].split(",")
        all_ched_positions = row["all_ched_posi"].split(",")
        pred_probas = row["pred_proba"].split(",")
        pred_types = row["pred_type"].split(",")
        pred_group_types = row["pred_group_type"].split(",")

        posi_to_type = dict(zip(all_ched_positions, pred_types))
        posi_to_group_type = dict(zip(all_ched_positions, pred_group_types))
        metal_types = [posi_to_type[i] for i in positions]
        metal_group_types = [posi_to_group_type[i] for i in positions]

        record = {
            "seq_id": seq_id.split("-")[1] if seq_id.startswith("AFDB") else seq_id,
            "pred_seq_num": ",".join(
                [f"{int(i) + 1}" for i in positions]
            ),  # to seq num
            "proba": ",".join(pred_probas),
            "metal_type": ",".join(metal_types),
            "metal_group_type": ",".join(metal_group_types),
        }

        exclude_keys = {
            "seq_id",
            "posi",
            "all_ched_posi",
            "all_ched_posi_",
            "pred_proba",
            "pred_type",
            "pred_group_type",
        }
        for k in row.index:
            if k not in exclude_keys:
                record[k] = row[k]
        records.append(record)

    return pd.DataFrame(records)


def main(argv):
    FLAGS = flags.FLAGS

    merge_and_reformat_preds(
        df_p=merge_files(FLAGS.p_path),
        df_tp=merge_files(FLAGS.tp_path),
        df_gtp=merge_files(FLAGS.gtp_path),
    ).to_csv(FLAGS.output_file, sep="\t", index=None)


if __name__ == "__main__":
    setup_args()
    app.run(main)
