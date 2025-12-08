#!/usr/bin/env Rscript

# ------------------------------
# Genome-wide ROH Manhattan Plot
# ------------------------------
# Usage:
#   Rscript roh_manhattan_genomewide.R \
#       results/roh/ \
#       results/plots/roh_manhattan_genomewide.png
# ------------------------------

library(ggplot2)
library(dplyr)
library(stringr)

args <- commandArgs(trailingOnly = TRUE)
roh_dir <- args[1]      # directory containing *.hom files
outfile <- args[2]      # output plot filename

# ----------------------
# Load all ROH files
# ----------------------
roh_files <- list.files(roh_dir, pattern = "\\.hom$", full.names = TRUE)

if(length(roh_files) == 0){
    stop("No .hom files found in directory: ", roh_dir)
}

message("Found ", length(roh_files), " ROH files.")

all_roh <- do.call(rbind, lapply(roh_files, function(f) {
    df <- read.table(f, header = TRUE, stringsAsFactors = FALSE)
    df$source_file <- basename(f)
    return(df)
}))

# ----------------------
# Clean chromosome names
# ----------------------
all_roh$CHR <- gsub("^chr", "", all_roh$CHR)  # remove chr prefix if present
all_roh$CHR <- as.character(all_roh$CHR)

# Standardize your dataset names (NC_058189.1 etc.)
all_roh$CHR <- factor(all_roh$CHR, levels = sort(unique(all_roh$CHR)))

# ----------------------
# Midpoint for each ROH
# ----------------------
all_roh$MID <- (all_roh$POS1 + all_roh$POS2) / 2

# ----------------------
# Create cumulative genomic coordinates
# ----------------------
chrom_sizes <- all_roh %>%
    group_by(CHR) %>%
    summarize(chr_max = max(MID, na.rm = TRUE))

chrom_sizes$cumulative <- cumsum(chrom_sizes$chr_max) - chrom_sizes$chr_max

all_roh <- all_roh %>% 
    left_join(chrom_sizes, by = "CHR") %>%
    mutate(BP_CUM = MID + cumulative)

# ----------------------
# Chromosome center positions for label placement
# ----------------------
axis_df <- all_roh %>% 
    group_by(CHR) %>%
    summarize(center = median(BP_CUM))

# ----------------------
# Plot
# ----------------------
p <- ggplot(all_roh, aes(x = BP_CUM, y = KB, color = CHR)) +
    geom_point(alpha = 0.65, size = 1.3) +
    scale_x_continuous(labels = axis_df$CHR, breaks = axis_df$center) +
    scale_color_manual(values = rep(c("steelblue3", "lightskyblue1"), length(unique(all_roh$CHR)))) +
    labs(
        title = "Genome-wide ROH Manhattan Plot",
        x = "Chromosomes",
        y = "ROH Length (KB)"
    ) +
    theme_minimal() +
    theme(
        legend.position = "none",
        axis.text.x = element_text(angle = 60, hjust = 1)
    )

ggsave(outfile, p, width = 16, height = 6, dpi = 300)
message("Saved plot to: ", outfile)


