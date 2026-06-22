# input
metaldb_rep_tax_info="../data/metaldb_repId-lca-numDomains.tsv"
# output
core_mbp_rep_tax_info="./tmp/core_repId-lca-numDomains.tsv"


awk '$3==3' $metaldb_rep_tax_info > $core_mbp_rep_tax_info