#!/usr/bin/env Rscript
library(ggplot2)
library(dplyr)

args <- commandArgs(trailingOnly = TRUE)
roh_dir <- args[1]
outfile <- args[2]

files <- list.files(roh_dir, pattern="\\.hom$", full.names=TRUE)

all <- lapply(files, function(f){
    df <- read.table(f, header=TRUE, stringsAsFactors=FALSE)
    if (nrow(df) == 0) return(NULL)
    df$CHRFILE <- basename(f)
    df
})

all <- bind_rows(all)

if (nrow(all) == 0){
    message("No ROH entries found ? writing blank output.")
    file.create(outfile)
    quit(save="no")
}

all$MID <- (all$POS1 + all$POS2) / 2

p <- ggplot(all, aes(x=MID, y=KB, color=CHR)) +
    geom_point(alpha=0.5, size=1) +
    theme_minimal() +
    labs(
        title = "Genome-wide ROH Manhattan Plot",
        x = "Chromosomal position",
        y = "ROH length (KB)"
    )

ggsave(outfile, p, width = 16, height = 6, dpi = 300)
message("Saved genome-wide plot: ", outfile)

