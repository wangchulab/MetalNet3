from itertools import combinations
from typing import List

import foldcomp
import networkx as nx
import pandas as pd
import tqdm
from absl import app, flags, logging
from Bio.PDB.PDBParser import PDBParser
from Bio.PDB.Residue import Residue
from Bio.PDB.Structure import Structure


def setup_arguments():
    flags.DEFINE_string("foldcomp_db", None, required=True, help="")
    flags.DEFINE_string("input", None, required=True, help="")
    flags.DEFINE_string("output", None, required=True, help="")


def parse_pdb_str(
    id: str,
    pdb_str: str,
    positions: List[int],
) -> tuple[Structure, float]:

    # extract related lines for single-chain protein
    lines = pdb_str.split("\n")
    result = []
    posi2plddts = dict()
    for l in lines:
        if l.startswith("ATOM"):
            resseq = int(l[22:26].split()[0])
            posi = resseq - 1
            plddt = float(l[60:66])
            posi2plddts[posi] = plddt
            if posi in positions:
                result.append(l)
    avg_plddt = sum(posi2plddts.values()) / len(posi2plddts)

    # build structure
    parser = PDBParser(QUIET=True)
    sb = parser.structure_builder
    sb.init_structure(id)
    parser._parse(result)
    sb.set_header(parser.get_header())

    return sb.get_structure(), avg_plddt


def filter_by_clique(
    positions: List[int],
    st: Structure,
    cb_threshold: float = 15,
    num_clique_member: int = 3,
) -> tuple[dict, list[list[int]]]:
    residues = set()
    for r in st.get_residues():
        r: Residue
        posi = r.id[1] - 1
        if posi in positions:
            residues.add(r)

    g = nx.Graph()
    for r1, r2 in combinations(residues, 2):
        if r1["CB"] - r2["CB"] <= cb_threshold:
            g.add_edge(r1, r2)

    qualified = []
    cliques = nx.algorithms.find_cliques(g)
    for c in cliques:
        if len(c) >= num_clique_member:
            qualified.append(c)

    sites = []
    posi2plddt = dict()
    for c in qualified:
        site = []
        for r in c:
            posi = r.id[1] - 1
            posi2plddt[posi] = r["CB"].get_bfactor()
            site.append(posi)
        sites.append(site)

    return posi2plddt, sites


def main(argv):
    FLAGS = flags.FLAGS
    foldcomp_db = FLAGS.foldcomp_db
    input_df = FLAGS.input
    output_df = FLAGS.output

    logging.info("Reading predicted records...")
    df = pd.read_table(input_df)
    seq_id_to_positions = dict(
        zip(
            df["seq_id"].map(lambda x: x.removeprefix("AFDB:") + "-model_v4"),
            zip(
                df["posi"].map(lambda x: [int(i) for i in x.split(",")]),
                df["pred"].map(lambda x: x.split(",")),
            ),
        )
    )
    del df
    logging.info("Done.")

    logging.info("Filtering by structure...")
    records = []
    with foldcomp.open(foldcomp_db) as db:
        for name, pdb in tqdm.tqdm(db):
            name = name.split(".")[0]
            if name not in seq_id_to_positions.keys():
                continue
            positions, preds = seq_id_to_positions[name]
            st, avg_plddt = parse_pdb_str(name, pdb, positions)
            posi_to_plddt, sites = filter_by_clique(positions, st)
            if len(posi_to_plddt) != 0:
                posi_to_pred = dict(zip(positions, preds))
                result = []
                for k in posi_to_plddt.keys():
                    result.append((k, posi_to_plddt[k], posi_to_pred[k]))
                result.sort(key=lambda x: x[0])

                records.append(
                    {
                        "seq_id": "AFDB:" + name.removesuffix("-model_v4"),
                        "avg_plddt": round(avg_plddt, 3),
                        "posi": ",".join([str(i[0]) for i in result]),
                        "pred": ",".join([str(i[2]) for i in result]),
                        "plddt": ",".join([str(i[1]) for i in result]),
                        "site": ";".join(
                            [",".join([str(j) for j in sorted(i)]) for i in sites]
                        ),
                    }
                )
    pd.DataFrame(records).to_csv(output_df, sep="\t", index=None)  # type: ignore
    logging.info("Done.")


if __name__ == "__main__":
    setup_arguments()
    app.run(main)
