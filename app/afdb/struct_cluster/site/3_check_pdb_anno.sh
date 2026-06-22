# input
pdb_anno="../../collect_annotation/pdb/tmp/pdb_metal_anno.tsv"
afdb50="../../_database/afdb_clusters/7-AFDB50-repId_memId.tsv"
afdb_cluster="../../_database/afdb_clusters/1-AFDBClusters-entryId_repId_taxId.tsv"
# output
anno_info="./tmp/pdb_anno_entryId_structRepId.tsv"


duckdb -c "
COPY (
    SELECT DISTINCT
        p.seq_id AS uniprot_id,
        s.column1 AS struct_cluster_rep_id
    FROM read_csv('$pdb_anno', sep='\t', header=True) p
    JOIN read_csv('$afdb50', sep='\t', header=False) a 
        ON p.seq_id = a.column1
    JOIN read_csv('$afdb_cluster', sep='\t', header=False) s 
        ON a.column0 = s.column0
) TO '$anno_info' (HEADER FALSE, DELIMITER '\t');
"
