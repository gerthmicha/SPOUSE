#!/bin/bash



for i in annotation/*/*.txt

do

	printf "$(basename ${i} .txt)," > reports/$(basename ${i})
	grep 'Length\|Count\|GC\|coding density\|tRNAs\|tmRNAs\|rRNAs\|ncRNAs\|CRISPR arrays\|CDSs\|pseudogenes\|hypotheticals\|sORFs' ${i} | cut -f2-20 -d':' | tr -d ' ' | tr '\n' ',' | sed 's/,$/\n/' >> reports/$(basename ${i})

done

echo "strain,size,contigs,%GC,cod.dens,tRNAs,tmRNAs,rRNAs,ncRNAs,CRISPR,CDS,pseudo,hypothetical,sORFs" | cat - reports/*.txt

rm reports/*.txt
