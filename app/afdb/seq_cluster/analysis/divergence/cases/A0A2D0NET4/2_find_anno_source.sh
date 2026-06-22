# input
## target structure cluster
s1="A0A1I3IPB0"
s2="A0A4Q9BGC7"
## target seq cluster with site anno
seq1="A0A419VWJ5"
seq2="A0LZX3"
afdb_cluster="../../../../../_database/afdb_clusters/1-AFDBClusters-entryId_repId_taxId.tsv"
mbp_cluster_anno="../../../../../collect_annotation/mbp_pro_anno/data/mbp_repId-annoLevel.tsv"
afdb50="../../../../../_database/afdb_clusters/7-AFDB50-repId_memId.tsv"
afdb_anno="../../../../../collect_annotation/afdb_anno/data/entryId-repId-pfamId-tedId-annoLevel-sp.tsv"
mbp_anno="../../../../../collect_annotation/mbp_pro_anno/data/entryId.tsv"
go_anno="../../../../../collect_annotation/go_terms/data/mbp_uniprot_id.tsv"
uniprot_anno="../../../../../collect_annotation/uniprot/data/entryId-seqNum-resi-metalResi.tsv"
pdb_anno="../../../../../collect_annotation/pdb/data/entryId-seqNum-resi-metalResi-pdbId.tsv"
# output
anno_source="./tmp/anno_entryId-repId-structRepId.tsv"

awk -F'\t' -v s1=$s1 -v s2=$s2 '
    NR==FNR {
        if ($2 == s1 || $2 == s2) {
            rep_to_struct_rep[$1] = $2
        }
        next
    }

    FILENAME==ARGV[2] {
        if ($1 in rep_to_struct_rep && $2 == 1) {
            target_reps[$1]
        }
        next
    }

    FILENAME==ARGV[3] {
        anno_mbps[$1]
        next
    }

    FILENAME==ARGV[4] {
        if ($1 in target_reps && $2 in anno_mbps) {
            print $2"\t"$1"\t"rep_to_struct_rep[$1]
        }
    }
' $afdb_cluster $mbp_cluster_anno $mbp_anno $afdb50 > $anno_source

targets=`awk '{print $1}' $anno_source`
for i in $targets
do
echo -n "Go anno: "
grep $i $go_anno
echo -n "UniProt anno: "
grep $i $uniprot_anno
echo -n "PDB anno: "
grep $i $pdb_anno
done
# Go anno: A0A1B7Z039
# UniProt anno: PDB anno: Go anno: A0A7L4ZFW4
# UniProt anno: PDB anno: Go anno: I3DVN0
# UniProt anno: PDB anno: Go anno: A0A5C8AHZ6
# UniProt anno: PDB anno: Go anno: A0A2E6VC03
# UniProt anno: PDB anno: Go anno: A0A1M6L4H0
# UniProt anno: PDB anno:

awk -F'\t' -v s1=$seq1 -v s2=$seq2 '($2 == s1 || $2 == s2) && (index($5, "3") || index($5, "4"))' $afdb_anno
# A0A1B7Z039      A0A419VWJ5      PF09360         1,3     0
# A0A1M6L4H0      A0LZX3  PF09360         1,3     0