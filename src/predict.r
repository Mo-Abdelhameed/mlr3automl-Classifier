# Required Libraries
library(jsonlite)
library(mlr3)
library(mlr3automl)

set.seed(42)

# Paths
ROOT_DIR <- getwd() # dirname(getwd())
MODEL_INPUTS_OUTPUTS <- file.path(ROOT_DIR, 'model_inputs_outputs')
INPUT_DIR <- file.path(MODEL_INPUTS_OUTPUTS, "inputs")
OUTPUT_DIR <- file.path(MODEL_INPUTS_OUTPUTS, "outputs")
INPUT_SCHEMA_DIR <- file.path(INPUT_DIR, "schema")
DATA_DIR <- file.path(INPUT_DIR, "data")
TRAIN_DIR <- file.path(DATA_DIR, "training")
TEST_DIR <- file.path(DATA_DIR, "testing")
MODEL_ARTIFACTS_PATH <- file.path(MODEL_INPUTS_OUTPUTS, "model", "artifacts")
PREDICTOR_DIR_PATH <- file.path(MODEL_ARTIFACTS_PATH, "predictor")
PREDICTOR_FILE_PATH <- file.path(PREDICTOR_DIR_PATH, "predictor.rds")
PREDICTIONS_DIR <- file.path(OUTPUT_DIR, 'predictions')
PREDICTIONS_FILE <- file.path(PREDICTIONS_DIR, 'predictions.csv')
TARGET_CLASSES_NAMES_FILE <- file.path(MODEL_ARTIFACTS_PATH, "target_classes.rds")


if (!dir.exists(PREDICTIONS_DIR)) {
  dir.create(PREDICTIONS_DIR, recursive = TRUE)
}

# Reading the schema
file_name <- list.files(INPUT_SCHEMA_DIR, pattern = "*.json")[1]
schema <- fromJSON(file.path(INPUT_SCHEMA_DIR, file_name))
features <- schema$features

numeric_features <- features$name[features$dataType != 'CATEGORICAL']
categorical_features <- features$name[features$dataType == 'CATEGORICAL']
id_feature <- schema$id$name
target_feature <- schema$target$name
target_classes <- schema$target$classes
model_category <- schema$modelCategory
nullable_features <- features$name[features$nullable == TRUE]


# Reading test data.
file_name <- list.files(TEST_DIR, pattern = "*.csv", full.names = TRUE)[1]
# Read the first line to get column names
header_line <- readLines(file_name, n = 1)
col_names <- unlist(strsplit(header_line, split = ",")) # assuming ',' is the delimiter
# Read the CSV with the exact column names
df <- read.csv(file_name, skip = 0, col.names = col_names, check.names=FALSE)

# Remove ids from testing dataframe
ids <- df[[id_feature]]
df[[id_feature]] <- NULL

target_classes_names = readRDS(TARGET_CLASSES_NAMES_FILE)

colnames(df) <- paste0("f", 1:ncol(df))
half_len <- nrow(df) %/% 2
df$target_feature <- sample(target_classes_names, size = nrow(df), replace = TRUE)
df$target_feature = as.factor(df$target_feature)

# Define prediction task
task = TaskClassif$new(id = "clf_task", backend = df, target = "target_feature")

# Load model
model = readRDS(PREDICTOR_FILE_PATH)

# Making predictions
predictions = model$predict(task)
prob = as.data.frame(predictions$prob)

prob[[id_feature]] <- ids

write.csv(prob, PREDICTIONS_FILE, row.names = FALSE)
