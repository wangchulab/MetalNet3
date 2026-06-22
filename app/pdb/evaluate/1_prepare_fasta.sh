# input
metal_chain_file="../collect_mbp/data/metal_chains.tsv"
mbps_fasta="../collect_mbp/tmp/mbp.fasta"
# output
metal_chain_fasta="./tmp/metal_chains.fasta"

awk '
    NR>1 {
        if ($7 == "H" || $7 == "C" || $7 == "E" || $7 == "D") {
            print $1"_"$2
        }
    }
' $metal_chain_file | sort -u | seqkit grep -f - $mbps_fasta -o $metal_chain_fasta