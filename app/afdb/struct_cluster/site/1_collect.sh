# input
metaldb="../../predict_afdb/data/pred_ge_3_clique_3.tsv"
seq_rep_file="../../seq_cluster/tmp/high_conf_pred_repId-entryId.tsv"
struct_rep_file="../tmp/repId-entryId.tsv"
# output
selected="./tmp/structRepId-entryId.tsv"

duckdb -c "
CREATE TABLE metal AS 
SELECT regexp_split_to_array(seq_id, '-')[2] as target_id, avg_plddt as plddt 
FROM read_csv('$metaldb', sep='\t', header=True);

COPY (
    WITH all_mappings AS (
        SELECT s.column0 as seq_rep, m.target_id, m.plddt
        FROM read_csv('$seq_rep_file', sep='\t', header=False) s
        JOIN metal m ON s.column1 = m.target_id
    ),
    struct_mapping AS (
        SELECT st.column0 as struct_rep, am.target_id, am.plddt
        FROM read_csv('$struct_rep_file', sep='\t', header=False) st
        JOIN all_mappings am ON st.column1 = am.seq_rep
    )
    SELECT struct_rep, arg_max(target_id, plddt) as best_target
    FROM struct_mapping
    GROUP BY struct_rep
) TO '$selected' (DELIMITER '\t', HEADER FALSE);
"
