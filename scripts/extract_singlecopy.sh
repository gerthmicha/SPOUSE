#!/bin/bash
ORTHO_NUMBER=$(grep 'Input proteomes' orthologs/last_run_info.txt | cut -f2)
FRACTION=$1
MIN_ORTHOS=$(echo "$ORTHO_NUMBER*$FRACTION" | bc | cut -f1 -d'.') 
sonicparanoid-extract -i orthologs/ortholog_groups.tsv -o orthogroups/singlecopy --single-copy-only -fd proteomes --fasta -maxsp $ORTHO_NUMBER -minsp $MIN_ORTHOS
mv orthogroups/singlecopy/*/*.faa orthogroups/singlecopy/ 
find orthogroups/singlecopy -mindepth 1 -maxdepth 1 -type d | xargs -I{} rm -rf {}
