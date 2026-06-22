# input
afdb_anno="../collect_annotation/afdb_anno/data/entryId-repId-pfamId-tedId-annoLevel-sp.tsv"
pfam_anno="../collect_annotation/pfam/data/pfamId.tsv"
pred_pfam_ids=./tmp/entryId-pfamIds-posis.tsv
pfam_file="../_database/Pfam/Pfam-A.regions.tsv"
# output
pfam_consitency="./data/pfamId-numPro-numPredPro-numAnnoPro-isAnno.tsv"


awk -F'\t' '
    NR>1 {
        print $1"\t"$5
    }
' $pfam_file | sort -u |\
awk -F'\t' '
    NR==FNR {
        afdb_ids[$1]
        if ($5 != "") {
            pro_anno_ids[$1]
        }
        next
    }

    FILENAME==ARGV[2] && FNR > 1 {
        if ($1 in afdb_ids) {
            pfam_id_to_total_num[$2] ++
            if ($1 in pro_anno_ids) {
                pfam_id_to_anno_num[$2] ++
            }
        }
        next
    }

    FILENAME==ARGV[3] {
        split($2, arr, ",")
        for (i in arr) {
            pfam_id = arr[i]
            pfam_id_to_pred_num[pfam_id] ++
        }
        next
    }

    FILENAME==ARGV[4] {
        pfam_anno_ids[$1]
        next
    }

    END {
        for (pfam_id in pfam_id_to_pred_num) {
            numPro = pfam_id_to_total_num[pfam_id]
            numPredPro = pfam_id_to_pred_num[pfam_id]
            numAnnoPro = pfam_id in pfam_id_to_anno_num ? pfam_id_to_anno_num[pfam_id] : 0
            isAnno = pfam_id in pfam_anno_ids ? 1 : 0
            print pfam_id"\t"numPro"\t"numPredPro"\t"numAnnoPro"\t"isAnno
        }
    }
' $afdb_anno - $pred_pfam_ids $pfam_anno > $pfam_consitency

# predicted mbp domains: 9570
wc -l $pfam_consitency

## no anno member: 846
awk '$4==0' $pfam_consitency  | wc -l