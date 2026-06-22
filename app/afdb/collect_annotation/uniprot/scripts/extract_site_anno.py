# this scripts is modified from
# https://github.com/wangchulab/MetalNet2/blob/main/app/metalloproteome/analysis/extra/scripts/annotate_proteome.py

import csv
import gzip

import pandas as pd
import tqdm
from absl import app, flags
from Bio import SeqIO
from Bio.SeqRecord import SeqRecord
from Bio.SwissProt import FeatureTable

metal_elements = {"ZN", "CA", "MG", "MN", "FE", "CU", "NI", "CO", "SF4", "FES", "F3S"}


def define_arguments():
    flags.DEFINE_string(
        "input_txt", None, required=True, help="txt records file, txt or gz"
    )
    flags.DEFINE_string("input_ligands", None, required=True, help="metal ligands, tsv")
    flags.DEFINE_string("output", None, required=True, help="anotation file")


def extract(
    swiss_file: str,
    chebi_to_metal: dict,
):
    open_func = gzip.open if swiss_file.endswith(".gz") else open

    with open_func(swiss_file, "rt") as handle:
        for r in SeqIO.parse(handle, "swiss"):
            r: SeqRecord
            features = r.features

            uniprot = r.id
            resi_seq_nums = []
            resis = []
            metal_resis = []

            for f in features:
                f: FeatureTable
                if f.type == "BINDING":
                    chebi = (
                        f.qualifiers["ligand_id"][6:]
                        if "ligand_id" in f.qualifiers.keys()
                        else " "
                    )  # ChEBI:CHEBI:...
                    if chebi in chebi_to_metal.keys():
                        metal_resi = chebi_to_metal[chebi]
                        locations = list(f.location)
                        for posi in locations:

                            resi_seq_nums.append(posi + 1)
                            resis.append(r.seq[posi])
                            metal_resis.append(metal_resi)

            if len(resi_seq_nums) > 0:
                result = [
                    uniprot,
                    ",".join([str(i) for i in resi_seq_nums]),
                    ",".join([str(i) for i in resis]),
                    ",".join([str(i) for i in metal_resis]),
                ]

                yield result


def main(argv):
    FLAGS = flags.FLAGS
    input_txt = FLAGS.input_txt
    input_ligands = FLAGS.input_ligands
    output = FLAGS.output

    df_metal_ligands = pd.read_csv(input_ligands, sep="\t")
    df_metal_ligands = df_metal_ligands[
        df_metal_ligands["metal_resi"].map(lambda x: x in metal_elements)
    ]
    dict_chebi_to_metal = dict(
        zip(df_metal_ligands["chebi"], df_metal_ligands["metal_resi"])
    )
    results = extract(input_txt, dict_chebi_to_metal)
    with open(output, "w", newline="") as f:
        writer = csv.writer(f, delimiter="\t", lineterminator="\n")
        for i in tqdm.tqdm(results):
            _ = writer.writerow(i)


if __name__ == "__main__":
    define_arguments()
    app.run(main)
