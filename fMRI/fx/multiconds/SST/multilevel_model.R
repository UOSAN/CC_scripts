library(lme4)
library(dplyr)

input_dir=""
ff = list.files(path = input_dir, pattern = "sub.*_events.tsv", full.names = TRUE)
filenames = dir(input_dir, pattern="sub.*_events.tsv", full.names = TRUE)

get_subject_id = function(filename) {
  # Get the subject ID from the filename
  match = regexpr("CC[[:digit:]]{3}", filename)
  subject_id = substr(filename, match, match + attr(match, "match.length") - 1)
}

subject_id = get_subject_id(filenames[1])

dataset = read.table(filenames[1], sep="\t", header = TRUE)
dataset = dplyr::select(dataset, duration, trial_type)
dataset = dplyr::rename(dataset, rt = duration, condition=trial_type)
dataset = tibble::rowid_to_column(dataset, var = "time")
dataset = dplyr::mutate(dataset, subject = subject_id)

for (filename in filenames[-1]) {
  # Read the data from each file
  df = read.table(filename, sep="\t", header = TRUE)
  
  subject_id = get_subject_id(filename)
  df = dplyr::select(df, duration, trial_type)
  df = dplyr::rename(df, rt = duration, condition=trial_type)
  df = tibble::rowid_to_column(df, var = "time")
  df = dplyr::mutate(df, subject = subject_id)
  dataset = rbind(dataset, df)
}

timeModel <- lmer(rt ~ time + condition + (1 | subject), data = dataset)
summary(timeModel)