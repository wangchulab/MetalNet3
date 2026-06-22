# input
afdb50="../../../../../_database/afdb_clusters/7-AFDB50-repId_memId.tsv"
reps_file="./tmp/repId-numPro-numPredPro-numSiteAnnoPro-annoLevel-structRepId.tsv"
afdb_fasta="../../../../../_database/afdb/afdb_uniprot_v4_fasta"
afdb="../../../../../_database/afdb_clusters/5-allmembers-repId-entryId-cluFlag-taxId.tsv"
afdb_high_conf_pred="../../../../../predict_afdb/data/pred_ge_3_clique_3.tsv"
# output
fasta_file="./tmp/266_cluster_seqs.fasta"
pred_fasta_file="./tmp/266_cluster_seqs_pred.fasta"
mmseqs_dir="./tmp/mmseqs/"
aligned_file="./tmp/266_cluster_seqs_pred_aligned.fasta"

# awk '{print $1}' $reps_file | awk 'NR==FNR {ids[$1]; next} $1 in ids {print "AF-"$2"-F1-model_v4.cif.gz"}' - $afdb50 |\
# seqkit grep -f - $afdb_fasta | seqkit fx2tab - | awk '{split($1, arr, "-"); print arr[2]"\t"$2}' | seqkit tab2fx - > $fasta_file
# 
# mmseqs easy-cluster $fasta_file $fasta_file.rep90 $mmseqs_dir \
#     --min-seq-id 0.9 \
#     -c 0.8 \
#     --cov-mode 0

# select pred in one cluster (rep first)
awk '
    NR==FNR && FNR > 1 {
        split($1, arr, "-")
        pred_ids[arr[2]]
        next
    }

    NR!=FNR {
        if (!($1 in rep_ids) && $2 in pred_ids) {
            print $2
            rep_ids[$1]
        }
    }
' $afdb_high_conf_pred $fasta_file.rep90_cluster.tsv | seqkit grep -f - $fasta_file > $pred_fasta_file

# only aligned pred seqs
clustalo-1.2.4-Ubuntu-x86_64 --in $pred_fasta_file --outfmt=fasta --threads=20 > $aligned_file