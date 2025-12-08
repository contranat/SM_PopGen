CHROMS = config["chromosomes"]

rule vcf_to_plink:
    input:
        "data/FILTERED_CHR_VCFS/{chrom}.filtered.vcf.gz"
    output:
        bed="results/plink/{chrom}.bed",
        bim="results/plink/{chrom}.bim",
        fam="results/plink/{chrom}.fam"
    shell:
        """
        plink --vcf {input} \
              --make-bed \
              --double-id \
              --allow-extra-chr \
              --out results/plink/{wildcards.chrom}
        """

rule roh:
    input:
        bed="results/plink/{chrom}.bed",
        bim="results/plink/{chrom}.bim",
        fam="results/plink/{chrom}.fam"
    output:
        "results/roh/{chrom}.hom"
    params:
        min_kb = config["roh_params"]["min_kb"],
        window_snp = config["roh_params"]["window_snp"],
        window_het = config["roh_params"]["window_het"],
        window_missing = config["roh_params"]["window_missing"]
    shell:
        """
        plink --bfile results/plink/{wildcards.chrom} \
              --homozyg \
              --homozyg-kb {params.min_kb} \
              --homozyg-window-snp {params.window_snp} \
              --homozyg-window-het {params.window_het} \
              --homozyg-window-missing {params.window_missing} \
              --allow-extra-chr \
              --out results/roh/{wildcards.chrom}
        """

rule froh:
    input:
        "results/roh/{chrom}.hom"
    output:
        "results/froh/{chrom}_froh.tsv"
    params:
        length=lambda wc: config["chrom_lengths"][wc.chrom]
    shell:
        """
        bash scripts/compute_froh.sh {wildcards.chrom} {input} {params.length} > {output}
        """

rule merge_froh:
    input:
        expand("results/froh/{chrom}_froh.tsv", chrom=CHROMS)
    output:
        "results/froh/merged_froh.tsv"
    shell:
        """
        cat {input} > {output}
        """

rule roh_manhattan_genomewide:
    input:
        roh_dir="results/roh/"
    output:
        "results/plots/roh_manhattan_genomewide.png"
    shell:
        """
        Rscript scripts/roh_manhattan_genomewide.R {input.roh_dir} {output}
        """

