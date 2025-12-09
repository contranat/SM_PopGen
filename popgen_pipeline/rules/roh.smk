import os

CHROMS = config["chromosomes"]
PLOT_CHR = config["PLOT_CHR"]

##############################################
# 1. Convert VCF ? PLINK
##############################################
rule vcf_to_plink:
    input:
        lambda wc: os.path.join(config["data_path"], f"{wc.chrom}.filtered.vcf.gz")
    output:
        bed = "results/plink/{chrom}.bed",
        bim = "results/plink/{chrom}.bim",
        fam = "results/plink/{chrom}.fam"
    shell:
        """
        plink --vcf {input} \
              --make-bed \
              --double-id \
              --allow-extra-chr \
              --out results/plink/{wildcards.chrom}
        """

##############################################
# 2. ROH per chromosome
##############################################
rule run_roh:
    input:
        bed = "results/plink/{chrom}.bed",
        bim = "results/plink/{chrom}.bim",
        fam = "results/plink/{chrom}.fam"
    output:
        "results/roh/{chrom}.hom"
    params:
        min_kb      = config["roh_parameters"]["min_kb"],
        window_snp  = config["roh_parameters"]["window_snp"],
        window_het  = config["roh_parameters"]["window_het"],
        window_miss = config["roh_parameters"]["window_missing"]
    shell:
        """
        plink \
            --bfile results/plink/{wildcards.chrom} \
            --homozyg \
            --homozyg-kb {params.min_kb} \
            --homozyg-window-snp {params.window_snp} \
            --homozyg-window-het {params.window_het} \
            --homozyg-window-missing {params.window_miss} \
            --allow-extra-chr \
            --out results/roh/{wildcards.chrom}
        """

##############################################
# 3. Compute FROH per chromosome
##############################################
rule compute_froh:
    input:
        hom = "results/roh/{chrom}.hom"
    output:
        "results/froh/{chrom}.froh.tsv"
    params:
        chrom_len = lambda wc: config["chrom_lengths"][wc.chrom]
    shell:
        """
        bash scripts/compute_froh.sh {wildcards.chrom} {input.hom} {params.chrom_len} > {output}
        """

##############################################
# 4. Merge FROH into genome-wide file
##############################################
rule merge_froh:
    input:
        expand("results/froh/{chrom}.froh.tsv", chrom=CHROMS)
    output:
        "results/froh/merged_froh.tsv"
    shell:
        "cat {input} > {output}"

##############################################
# 5. Manhattan plot per chromosome
##############################################
rule roh_manhattan_chr:
    input:
        hom = "results/roh/{chrom}.hom"
    output:
        png = "results/plots/roh_{chrom}.png"
    shell:
        """
        Rscript scripts/roh_manhattan.R {input.hom} {output.png}
        """

##############################################
# 6. Genome-wide Manhattan plot
##############################################
rule roh_manhattan_genomewide:
    input:
        roh_dir = "results/roh"
    output:
        "results/plots/roh_manhattan_genomewide.png"
    shell:
        """
        Rscript scripts/roh_manhattan_genomewide.R {input.roh_dir} {output}
        """

##############################################
# 7. Single chromosome plot (configured)
##############################################
rule roh_manhattan_single:
    input:
        f"results/roh/{PLOT_CHR}.hom"
    output:
        f"results/plots/roh_{PLOT_CHR}.png"
    shell:
        """
        Rscript scripts/roh_manhattan.R {input} {output}
        """

