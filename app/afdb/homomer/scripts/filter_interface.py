import traceback
from itertools import combinations
from typing import List

import networkx as nx
import pandas as pd
import tqdm
from absl import app, flags, logging
from Bio.PDB.PDBParser import PDBParser
from Bio.PDB.Residue import Residue
from Bio.PDB.Structure import Structure


def setup_arguments():
    flags.DEFINE_string("pdb_files", None, required=True, help="")
    flags.DEFINE_string("input", None, required=True, help="")
    flags.DEFINE_string("output", None, required=True, help="")


def check_struct(
    pred_seq_nums: List[int],
    domain_lower_bound: int,
    st: Structure,
    threshold: float = 15,
    num_clique_member: int = 3,
):
    residues = set()
    for r in st.get_residues():
        r: Residue
        if r.id[1] in pred_seq_nums:  # in all chains
            residues.add(r)

    g = nx.Graph()
    for r1, r2 in combinations(residues, 2):
        if all(["CB" in r1, "CB" in r2]) and r1["CB"] - r2["CB"] <= threshold:
            g.add_edge(r1, r2)

    qualified: list[list[Residue]] = []
    cliques = nx.algorithms.find_cliques(g)
    for c in cliques:
        if len(c) >= num_clique_member:
            chains = set()
            for n in c:
                n: Residue
                chains.add(n.get_full_id()[2])
            if len(chains) >= 2:
                qualified.append(c)

    added_site_nums = set()
    sites: list[tuple[str, str]] = []
    seq_nums = set()
    for c in qualified:
        seq_num_resis = [(r.id[1], r) for r in c]
        seq_num_resis.sort(key=lambda x: x[0])

        # we here assume the set of seq nums defines a interface site
        site_nums = ",".join(list(set([str(x[0]) for x in seq_num_resis])))
        if site_nums in added_site_nums:
            continue
        added_site_nums.add(site_nums)

        all_seq_nums = []
        all_chain_names = []
        for seq_num, r in seq_num_resis:
            seq_nums.add(seq_num)
            all_seq_nums.append(str(seq_num))
            all_chain_names.append(r.get_full_id()[2])

        sites.append((",".join(all_seq_nums), ",".join(all_chain_names)))

    if len(sites) == 0:
        return None

    seq_nums = sorted(list(seq_nums))
    seq_nums_str = ",".join([str(i) for i in seq_nums])
    positions_str = ",".join([str(i + domain_lower_bound - 2) for i in seq_nums])
    site_seq_nums_str = ";".join([i[0] for i in sites])
    site_chain_names_str = ";".join([i[1] for i in sites])

    return positions_str, seq_nums_str, site_seq_nums_str, site_chain_names_str


def main(argv):
    FLAGS = flags.FLAGS
    pdb_files = FLAGS.pdb_files
    input_df = FLAGS.input
    output_df = FLAGS.output

    logging.info("Loading input...")
    df_pdb_files = pd.read_table(pdb_files)
    dict_pdb_files = dict(
        zip(df_pdb_files["seq_id"], zip(df_pdb_files["file"], df_pdb_files["domain"]))
    )
    df_pred = pd.read_table(input_df)
    logging.info("Done.")

    logging.info("Parsing...")
    records = []
    for _, row in tqdm.tqdm(df_pred.iterrows(), total=len(df_pred)):
        seq_id = row["seq_id"].split("-")[1]
        positions = [int(i) for i in row["posi"].split(",")]
        pdb_file, domain = dict_pdb_files[seq_id]
        domain_start = 1 if domain == " " else eval(domain)[0]

        seq_nums = [p + 2 - domain_start for p in positions]
        try:
            result = check_struct(
                seq_nums,
                domain_start,
                PDBParser(QUIET=True).get_structure(seq_id, pdb_file),
            )
        except:
            traceback.print_exc()
            logging.error(f"Failed in {seq_id}.")
            continue
        if result is not None:
            positions_str, seq_nums_str, site_positions_str, site_chain_names_str = (
                result
            )
            records.append(
                {
                    "seq_id": row["seq_id"],
                    "posi": positions_str,
                    "pdb_seq_num": seq_nums_str,
                    "site": site_positions_str,
                    "site_chain_name": site_chain_names_str,
                }
            )
    pd.DataFrame(records).to_csv(output_df, sep="\t", index=None)  # type: ignore
    logging.info("Done.")


if __name__ == "__main__":
    setup_arguments()
    app.run(main)
