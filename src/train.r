# Required Libraries
library(jsonlite)
library(mlr3)
library(mlr3automl)

set.seed(42)

# Define directories and paths
ROOT_DIR <- dirname(getwd())
MODEL_INPUTS_OUTPUTS <- file.path(ROOT_DIR, 'model_inputs_outputs')
INPUT_DIR <- file.path(MODEL_INPUTS_OUTPUTS, "inputs")
INPUT_SCHEMA_DIR <- file.path(INPUT_DIR, "schema")
DATA_DIR <- file.path(INPUT_DIR, "data")
TRAIN_DIR <- file.path(DATA_DIR, "training")
MODEL_ARTIFACTS_PATH <- file.path(MODEL_INPUTS_OUTPUTS, "model", "artifacts")
PREDICTOR_DIR_PATH <- file.path(MODEL_ARTIFACTS_PATH, "predictor")
PREDICTOR_FILE_PATH <- file.path(PREDICTOR_DIR_PATH, "predictor.rds")
TARGET_CLASSES_NAMES_FILE <- file.path(MODEL_ARTIFACTS_PATH, "target_classes.rds")


if (!dir.exists(MODEL_ARTIFACTS_PATH)) {
    dir.create(MODEL_ARTIFACTS_PATH, recursive = TRUE)
}
if (!dir.exists(file.path(MODEL_ARTIFACTS_PATH, "predictor"))) {
    dir.create(file.path(MODEL_ARTIFACTS_PATH, "predictor"))
}


# Reading the schema
# The schema contains metadata about the datasets. 
# We will use the scehma to get information about the type of each feature (NUMERIC or CATEGORICAL)
# and the id and target features, this will be helpful in preprocessing stage.

file_name <- list.files(INPUT_SCHEMA_DIR, pattern = "*.json")[1]
schema <- fromJSON(file.path(INPUT_SCHEMA_DIR, file_name))
features <- schema$features

numeric_features <- features$name[features$dataType == "NUMERIC"]
categorical_features <- features$name[features$dataType == "CATEGORICAL"]
id_feature <- schema$id$name
target_feature <- schema$target$name
model_category <- schema$modelCategory
nullable_features <- features$name[features$nullable == TRUE]

# Reading training data
file_name <- list.files(TRAIN_DIR, pattern = "*.csv")[1]
# Read the first line to get column names
header_line <- readLines(file.path(TRAIN_DIR, file_name), n = 1)
col_names <- unlist(strsplit(header_line, split = ",")) # assuming ',' is the delimiter
# Read the CSV with the exact column names
df <- read.csv(file.path(TRAIN_DIR, file_name), skip = 0, col.names = col_names, check.names=FALSE)

df[[id_feature]] <- NULL
target = df[[target_feature]]
df[[target_feature]] <- NULL


colnames(df) <- paste0("f", 1:ncol(df))

df[["target_feature"]] <- target
df$target_feature = as.factor(df$target_feature)

saveRDS(unique(df$target_feature), TARGET_CLASSES_NAMES_FILE)

task = TaskClassif$new(id = "clf_task", backend = df, target = "target_feature")


# Run automl
automl = AutoML(task)
automl$train()

# Get the best model
saveRDS(automl, PREDICTOR_FILE_PATH)