configfile: "config.yaml"

wildcard_constraints:
    sample="\\w+",

SAMPLES, = glob_wildcards("genome_fastas/{sample}.fas")

rule all:
    input:
        "orthologs/ortholog_groups.tsv",
        "reports/genomestats.csv",
        "test2.txt"

rule bakta:
    input: 
       "genome_fastas/{sample}.fas"
    output:
       "annotation/{sample}/{sample}.faa",
       "annotation/{sample}/{sample}.txt",
       "annotation/{sample}/{sample}.tsv",
       "annotation/{sample}/{sample}.ffn",
       "annotation/{sample}/{sample}.fna",
       "annotation/{sample}/{sample}.embl",
       "annotation/{sample}/{sample}.gff3",
       "annotation/{sample}/{sample}.gbff",
    conda:
        "envs/bakta.yaml"
    threads: 8 
    params:
        db_path=config["bakta_db_path"],
        translation_table=config["translation_table"]
    shell:
        """
        bakta --force --db {params.db_path} --output annotation/{wildcards.sample} --skip-plot --prefix {wildcards.sample} --locus-tag {wildcards.sample} --translation-table {params.translation_table} --threads {threads} --genus Spiroplasma --species sp. --strain {wildcards.sample} {input}
        """

rule stats:
    input: 
        txt = expand("annotation/{sample}/{sample}.txt", sample = SAMPLES)
    output:
        "reports/genomestats.csv"
    threads: 64 
    shell:
        """
        mkdir -p reports
        scripts/stats.sh >> {output}
        """

rule checkm:
    input: 
        expand("genome_fastas/{sample}.fas", sample = SAMPLES)
    output:
        "reports/checkm.tsv"
    conda:
        "envs/checkm.yaml"
    threads: 64
    shell:
        """
        checkm taxonomy_wf --tab_table -f reports/checkm.tsv -t {threads} -x fas order Entomoplasmatales genome_fastas reports/checkm
        """

rule reports:
    input:
        "reports/checkm.tsv",
        "reports/genomestats.csv"
    output:
        "reports/checkm.html",
        "reports/genomestats.html"
    conda:
        "envs/csvtotable.yaml"
    shell:
        """
        csvtotable reports/genomestats.csv reports/genomestats.html
        csvtotable -d "\t" reports/checkm.tsv reports/checkm.html 
        """

rule proteomes:
    input: 
        expand("annotation/{sample}/{sample}.faa", sample= SAMPLES)
    output:
        "proteomes/{sample}.faa"
    shell:
        """
        mkdir -p proteomes
        cp annotation/{wildcards.sample}/{wildcards.sample}.faa {output}    
        """

rule orthologs:
    input:
        expand("proteomes/{sample}.faa", sample= SAMPLES)
    output:
        "orthologs/ortholog_groups.tsv"
    conda:
        "envs/sonicparanoid.yaml"
    threads: 64
    shell:
        """
        sh scripts/sonicparanoid.sh
        """

checkpoint single_copy:
    input:
        "orthologs/ortholog_groups.tsv"
    output:
        directory("orthogroups/singlecopy")
    conda:
        "envs/sonicparanoid.yaml"
    params:
        prop_taxa=config["prop_taxa"]
    shell:
        """
        sh scripts/extract_singlecopy.sh {params.prop_taxa}
        """ 

rule align:
    input:
        "orthogroups/singlecopy/{i}.faa"
    output:
        "alignments/{i}.fas"
    conda:
        "envs/mafft.yaml"
    threads: 8
    shell:
        """     
        mkdir -p alignments 
        linsi --thread {threads} {input} |sed 's/GCA_/GCA/' | sed 's/GCF_/GCF/' | sed 's/_.*//g' > {output}
        """

rule recombination:
    input:
        "alignments/{j}.fas"
    output:
        "alignments/{j}.philog"
    conda:
        "envs/phipack.yaml"
    shell:
        """
        for w in {{10,20,30,40,50,100,200}}
        do
          Phi  -f {input} -w ${{w}} -t A >> {output}
        done
        """

def aggregate_input(wildcards):
    checkpoint_output = checkpoints.single_copy.get(**wildcards).output[0]
    return expand('alignments/{i}.philog',
           i=glob_wildcards(os.path.join(checkpoint_output, '{i}.faa')).i)

rule concat:
    input:
        aggregate_input
    output:
        matrix= "analysis/supermat.fas",
        test= "test2.txt",
        partition= "analysis/partition.txt" 
    conda:
        "envs/phyx.yaml"
    shell:
        """
        sh scripts/recombination.sh
        mkdir analysis
        pxcat -p {output.partition} -o {output.matrix} -s alignments/*.fas
        touch "test2.txt"
        """

