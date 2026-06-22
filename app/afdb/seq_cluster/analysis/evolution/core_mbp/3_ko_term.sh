# input
rep_ids="./tmp/core_repId-lca-numDomains.tsv"
metaldb_seq_ids="../../../../predict_afdb/analysis/taxonomy/tmp/metaldb_repId-entryId-taxId.tsv"
fasta_file="../../../../predict_afdb/tmp/pred_ge_3_clique_3.fasta"
eggnog_db="../../../../_database/eggnog/"
# tmp
core_fasta_file="./tmp/core_metaldb.fasta"
# output
emapper_dir="./tmp/emapper/"
core_rep_ko="./data/repId-ko.tsv"
kegg_pathway="./data/rep_kegg_pathway.txt"

awk '
    NR==FNR {
        ids[$1];
        next
    }

    $1 in ids {
        print "AFDB:AF-"$2"-F1"
    }
' $rep_ids $metaldb_seq_ids | seqkit grep -f - $fasta_file > $core_fasta_file

source ~/mamba.rc
mamba activate metalnet-helper
emapper.py -i $core_fasta_file --itype proteins --cpu 16 --data_dir $eggnog_db --output_dir $emapper_dir -o core_metaldb

awk -F'\t' '
    NR==FNR {
        ids[$1]
        next
    }

    {
        split($1, arr, "-")
        if (arr[2] in ids) {
            if ($12 != "-") {
                split($12, arr2, ",")
                for (i in arr2) {
                    split(arr2[i], arr3, ":")
                    print arr[2]"\t"arr3[2]
                }
            }
        }
    }
' $rep_ids $emapper_dir/core_metaldb.emapper.annotations > $core_rep_ko

# in https://www.kegg.jp/kegg/mapper/reconstruct.html
# and get $kegg_pathway