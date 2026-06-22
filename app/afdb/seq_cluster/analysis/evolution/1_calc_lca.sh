# input
metaldb_tax="../../../predict_afdb/analysis/taxonomy/tmp/metaldb_repId-entryId-taxId.tsv"
# tmp
metaldb_grouped="./tmp/metaldb_repId-taxIds.tsv"
tax_domains_lookup="./tmp/taxId_domain.tsv"
metaldb_lca="./tmp/metaldb_lca.tsv"
# output
metaldb_rep_tax_info="./data/metaldb_repId-lca-numDomains.tsv"


# taxonkit list --ids 131567 | taxonkit lineage | taxonkit reformat -f "{k}" -a | awk -F'\t' '$3 != "" { print $1"\t"$3 }' > $tax_domains_lookup

group_tax_id_by_rep_id() {
    duckdb -c "
    COPY (
        SELECT
            column0,
            string_agg(
                DISTINCT CAST(column2 AS VARCHAR),
                ' '
            )
        FROM read_csv(
            '$1',
            header = FALSE,
            sep = '\t',
            columns = {
                'column0': 'VARCHAR',
                'column1': 'VARCHAR',
                'column2': 'INT'
            }
        )
        GROUP BY column0
    ) TO '$2'
    (DELIMITER '\t', HEADER FALSE);
    "
}

get_lca() {
    awk -F'\t' '{print $2}' $1 | taxonkit lca | awk -F'\t' '{print $2}' > $2
}

get_tax_info() {
    paste $1 $2 |
    awk -F'\t' '
        NR==FNR {
            tax_id_to_domain[$1] = $2
            next
        }
        {
            delete seen_domains
            num_domain=0
            split($2, arr, " ")

            for (i in arr) {
                tax_id = arr[i]
                if (tax_id in tax_id_to_domain) {
                    domain = tax_id_to_domain[tax_id]
                    seen_domains[domain] = 1
                }
            }
            num_domain=length(seen_domains)

            print $1"\t"$3"\t"num_domain
        }
    ' $tax_domains_lookup - > $3
}

group_tax_id_by_rep_id $metaldb_tax $metaldb_grouped
get_lca $metaldb_grouped $metaldb_lca
get_tax_info $metaldb_grouped $metaldb_lca $metaldb_rep_tax_info