#!/usr/bin/env Rscript
# Run from command line as:
# $ Rscript rescorla_wagner.R --input /path/to/multiconds/files
args = commandArgs(trailingOnly=TRUE)

input_dir=""
if (length(args)!=2 && input_dir=="") {
  stop("Input directory argument must be supplied (--input input directory).\n", call.=FALSE)
} else if (length(args)==2) {
  cat(args[1], "\n")
  cat(args[2], "\n")
  input_dir = args[2]
}

library(mcplR)
library(tidyverse)

# Create learning models for go-trials only
filenames = dir(input_dir, pattern="sub.*_go.*tsv", full.names = TRUE)
for (i in 1:length(filenames)) {
  filename = filenames[i]
  df = read.table(filename, sep="\t", header = FALSE)

  learning_model = RescorlaWagner(V1~V2, data=df)

  predictions_df = as.data.frame(predict(learning_model))
  ggplot(predictions_df) +
    geom_point(mapping=aes(x=as.numeric(rownames(predictions_df)), y=V1, shape="Predicted")) +
    geom_line(mapping=aes(x=as.numeric(rownames(df)), y=df$V1, color="Measured")) +
    coord_cartesian(xlim=c(0,50), ylim=c(0,1)) +
    xlab("Trial number") +
    ylab("RT (s)") +
    scale_color_manual("", values=c("Measured"="black")) +
    scale_shape_manual("", values=c("Predicted"=1)) +
    theme(legend.position = "bottom")
  plotname = sprintf('plot_CC%03d.png', i)
  ggsave(plotname, width = 5, height = 5)

  f_learning_model = fit(learning_model)
  cat(filename, "\t", f_learning_model@parStruct@parameters["alpha"], "\n")
}

# Create learning models for go-trials following a stop trial
filenames = dir(input_dir, pattern="sub.*_stop.*tsv", full.names = TRUE)
for (i in 1:length(filenames)) {
  filename = filenames[i]
  df = read.table(filename, sep="\t", header = FALSE)
  
  learning_model = RescorlaWagner(V1~V2, data=df)
  
  f_learning_model = fit(learning_model)
  cat(filename, "\t", f_learning_model@parStruct@parameters["alpha"], "\n")
}
