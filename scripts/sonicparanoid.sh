#!/bin/bash
DATE=$( date '+%F_%H:%M:%S' )
sonicparanoid -i proteomes -p sp2-run-$DATE -ot -t 32 -o orthologs
cp orthologs/runs/sp2-run-$DATE/ortholog_groups/ortholog_groups.tsv orthologs/

ORTHO_NUMBER=$(grep 'Input proteomes' orthologs/last_run_info.txt | cut -f2)
sonicparanoid-extract -i orthologs/ortholog_groups.tsv -o orthogroups/all -fd proteomes --fasta -maxsp $ORTHO_NUMBER
