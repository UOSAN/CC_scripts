library(lme4)
library(dplyr)

# input_dir is the location of the BIDS-formatted events files
input_dir=""
filenames = dir(input_dir, pattern="sub.*_events.tsv", full.names = TRUE)
group_file = dir(input_dir, pattern="is_control.tsv", full.names = TRUE)

get_subject_id = function(filename) {
  # Get the subject ID from the filename
  match = regexpr("CC[[:digit:]]{3}", filename)
  subject_id = substr(filename, match, match + attr(match, "match.length") - 1)
}

subject_id = get_subject_id(filenames[1])

# Read file containing if subject is in treatment group or in control group
control_df = read.table(group_file, sep = '\t', header = TRUE, stringsAsFactors = FALSE)
group = control_df$is_treatment[control_df$subject_id == subject_id]

# Read file, select only the duration and trial_type columns, ignoring the onset column,
# create a column based on row number, and rename some columns.
dataset = read.table(filenames[1], sep="\t", header = TRUE)
dataset = dplyr::select(dataset, duration, trial_type)
dataset = dplyr::rename(dataset, rt = duration, condition=trial_type)
dataset = tibble::rowid_to_column(dataset, var = "time")
dataset = dplyr::mutate(dataset, subject = subject_id)
dataset = tibble::add_column(dataset, is_treatment = group)

for (filename in filenames[-1]) {
  # Read the data from each file
  df = read.table(filename, sep="\t", header = TRUE)

  subject_id = get_subject_id(filename)
  group = control_df$is_treatment[control_df$subject_id == subject_id]

  df = dplyr::select(df, duration, trial_type)
  df = dplyr::rename(df, rt = duration, condition=trial_type)
  df = tibble::rowid_to_column(df, var = "time")
  df = dplyr::mutate(df, subject = subject_id)
  df = tibble::add_column(df, is_treatment = group)
  dataset = rbind(dataset, df)
}

# Add new variables to dataset corresponding to correct-stop and failed-go conditions
dataset$conditioncorrect_stop = as.numeric(dataset$condition == "correct-stop")
dataset$conditionfailed_go = as.numeric(dataset$condition == "failed-go")
# Then create a time based linear model.
timeModel <- lmer(rt ~ time + condition + time * conditioncorrect_stop +
                    time * conditionfailed_go + is_treatment +
                    time * is_treatment + time * is_treatment * conditioncorrect_stop +
                    time * is_treatment * conditionfailed_go +
                    (1 | subject), data = dataset)
summary(timeModel)
