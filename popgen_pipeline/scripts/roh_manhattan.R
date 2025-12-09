#!/usr/bin/env Rscript
library(ggplot2)
library(dplyr)

args <- commandArgs(trailingOnly = TRUE)
homfile <- args[1]
outfile <- args[2]

df <- read.table(homfile, header = TRUE, stringsAsFactors = FALSE)

if (nrow(df) == 0) {
    message("HOM file is empty: ", homfile, " ? skipping plot.")
    file.create(outfile)
    quit(save="no")
}

df$MID <- (df$POS1 + df$POS2) / 2

p <- ggplot(df, aes(x = MID, y = KB)) +
    geom_point(alpha = 0.6, size = 1.2, color = "steelblue") +
    theme_minimal() +
    labs(
        title = paste("ROH Manhattan Plot ?", basename(homfile)),
        x = "Genomic position (bp)",
        y = "ROH length (KB)"
    )

ggsave(outfile, p, width = 10, height = 4, dpi = 300)
message("Saved plot: ", outfile)

