#!/bin/bash
#
#

# Directory with your per-chromosome VCFs (can pass as first argument)
VCF_DIR=${1:-.}

for f in "${VCF_DIR}"/*.filtered.vcf.gz
do
    # Example filename: NC_058197.1.filtered.vcf.gz
    base=$(basename "$f")
    chrom=${base%.filtered.vcf.gz}   # -> NC_058197.1

    len=$(bcftools view -h "$f" | \
          awk -v c="$chrom" '
              match($0, "ID=" c ",length=([0-9]+)", a) {print a[1]}
          ')

    echo -e "${chrom}\t${len}"
done


