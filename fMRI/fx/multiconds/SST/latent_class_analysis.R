library(mclust)
library(dplyr)

# input_dir is the location of the BIDS-formatted events files
input_dir=""
filenames = dir(input_dir, pattern="latent_class_analysis.tsv", full.names = TRUE)

dataset = read.table(filenames[1], sep="\t", header = TRUE)
dataset = dplyr::select(dataset, failed_go, mean_rt, std_dev_rt)

BIC = mclustBIC(dataset)
plot(BIC)
summary(BIC)

ICL = mclustICL(dataset)
plot(ICL)
summary(ICL)

model_VEI4 = Mclust(dataset, modelNames = 'VEI', G = 4, x = BIC)
plot(model_VEI4, what = 'classification')

model_VVI2 = Mclust(dataset, modelNames = 'VVI', G = 2, x = BIC)
plot(model_VVI2, what = 'classification')


means = data.frame(model_VEI4$parameters$mean, stringsAsFactors = FALSE) %>%
  tibble::rownames_to_column() %>%
  rename(manifest = rowname)
# summary(model_VEI4)
# 
# mclustBootstrapLRT(dataset, modelName = 'VEI')