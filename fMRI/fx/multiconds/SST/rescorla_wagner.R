#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)

input_dir=""
if (length(args)!=2) {
  stop("Input directory argument must be supplied (--input input directory).\n", call.=FALSE)
} else if (length(args)==2) {
  cat(args[1], "\n")
  cat(args[2], "\n")
  input_dir = args[2]
}

library(mcplR)
library(tidyverse)

filenames = dir(input_dir, pattern="sub.*_go.*tsv", full.names = TRUE)
for (i in 1:length(filenames)) {
  filename = filenames[i]
  blah = read.table(filename, sep="\t", header = FALSE)

  learning_model = RescorlaWagner(V1~V2, data=blah)

  f_learning_model = fit(learning_model)
  cat(filename, "\t", f_learning_model@parStruct@parameters["alpha"], "\n")
}
