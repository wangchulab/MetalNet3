# input
metaldb_taxId="../tmp/metaldb_repId-entryId-taxId.tsv"
taxId_lineage="../tmp/taxId-lineage.tsv"
# output
sampled_proteins_600k="./tmp/sampled_600k_repId-entryId-domain.tsv"


duckdb -c "

CREATE VIEW metal_data AS 
SELECT * FROM read_csv_auto('$metaldb_taxId', sep='\t', header=False, 
    names=['repId', 'entryId', 'taxId']);

CREATE VIEW tax_data AS 
SELECT * FROM read_csv_auto('$taxId_lineage', sep='\t', header=False, 
    names=['taxId', 'lineage']);

CREATE VIEW protein_with_domain AS
SELECT 
    m.repId, 
    m.entryId, 
    split_part(t.lineage, '|', 1) AS domain
FROM metal_data m
JOIN tax_data t ON m.taxId = t.taxId
WHERE domain IN ('Archaea', 'Bacteria', 'Eukaryota');

CREATE VIEW domain_reps_per_cluster AS
SELECT repId, entryId, domain
FROM (
    SELECT *,
           row_number() OVER (
             PARTITION BY repId, domain
             ORDER BY hash(repId || entryId)
           ) AS rn
    FROM protein_with_domain
) 
WHERE rn = 1;

CREATE TABLE final_sample_set AS
SELECT repId, entryId, domain
FROM (
    SELECT *,
           row_number() OVER (
             PARTITION BY domain
             ORDER BY hash(entryId)
           ) AS rn
    FROM domain_reps_per_cluster
)
WHERE (domain = 'Archaea'   AND rn <= 200000)
   OR (domain = 'Bacteria'  AND rn <= 200000)
   OR (domain = 'Eukaryota' AND rn <= 200000);

COPY final_sample_set TO '$sampled_proteins_600k' (HEADER FALSE, DELIMITER '\t');
"
