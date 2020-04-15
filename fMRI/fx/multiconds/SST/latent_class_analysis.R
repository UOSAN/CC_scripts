library(mclust)
library(dplyr)

# input_dir is the location of the BIDS-formatted events files
input_dir=""
filenames = dir(input_dir, pattern="latent_class_analysis.tsv", full.names = TRUE)

temp = read.table(filenames[1], sep="\t", header = TRUE)
dataset = dplyr::select(temp, failed_go, mean_rt, std_dev_rt)

BIC = mclustBIC(dataset)
plot(BIC)
summary(BIC)

ICL = mclustICL(dataset)
plot(ICL)
summary(ICL)

model_VEI4 = Mclust(dataset, modelNames = 'VEI', G = 4, x = BIC)
plot(model_VEI4, what = 'classification')

cbind(select(temp, subject_id), model_VEI4$classification)

model_VVI2 = Mclust(dataset, modelNames = 'VVI', G = 2, x = BIC)
plot(model_VVI2, what = 'classification')

# summary(model_VEI4)
# 
# mclustBootstrapLRT(dataset, modelName = 'VEI')