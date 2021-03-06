setwd("/Users/DVyshenska/R_wd")
source("sip-norm-functions.R")
#######
# Section one -------------------------------------------------

# DATA IMPORT AND PARSING
# importing metadata and coverage files
raw_files_path <- "./stat_files_clean/"
sp_meta <- read.csv("spikes_meta.csv", check.names = F, stringsAsFactors = F)
# impoaring and parsing coverage data from mags and spikins
df_list <- parse_bbmap_cov(raw_files_path, sp_meta)

# preparing spike-ins data to be an input for get_scale_factors
sequins_df <- df_list$spequins # retreaving only spike-ins data
#######
# step only for sequin article data - filtering out only these sequins
# that are same concentrations across ALL samples
mixes_sequins_meta <- read.csv("sequins_mixes_meta.csv", check.names = F,
                               stringsAsFactors = F)
same_sequins <- mixes_sequins_meta$`Metagenome sequin ID`[mixes_sequins_meta$`Mix A (relative abundance)` == mixes_sequins_meta$`Mix B (relative abundance)`]
sequins_df <- sequins_df[rownames(sequins_df) %in% same_sequins,]
######
# addint metadata (rel_conc) to sequins coverage table
sp_meta <- sp_meta[order(sp_meta[,1]),] 
rownames(sp_meta) <- sp_meta[,1]
sequins_df <- merge(sequins_df, sp_meta["Mix A (relative abundance)"], by=0)
colnames(sequins_df)[which(colnames(sequins_df) == "Mix A (relative abundance)")] <- "rel_conc"
rownames(sequins_df) <- sequins_df$Row.names
sequins_df <- sequins_df[,-which(colnames(sequins_df) == "Row.names")]


# Section two ----------------------------------------------------------------

# DATA TRANSFORMATION
# doing log2(x+1) tranformation for the counts
log2sequins_df <- log2(sequins_df + 1)
log2mags <- log2(df_list$mags + 1)


# Section three ----------------------------------------------------------------
# DATA NORMALIZATIONS


# LOG LM SCALING (Log transform only coverage)
# getting linear regression scaling factors
#source("sip-norm-functions.R")
log_seq_realCon <- log2(sequins_df[,-7] + 1)
log_seq_realCon$rel_conc <- sequins_df$rel_conc

test_res2 <- get_scale_factors_sd(log_seq_realCon,thresholdPerMean = 50)
# normalizing using linear regression scaling factors
data_norm2 <- lm_normalize(sampl_data = log2mags, scaleVal_df = test_res2$scaleVal_df)
write.csv(data_norm2, "normalized_tables/coverage_logCovOnly_lmScaling.csv")

input_table <- reorder_df(data_norm2)
plot_stackbar(plot_df = input_table, file_name = "cov_logCovOnly_lm.pdf")


# LOG LM SCALING
# getting linear regression scaling factors
#source("sip-norm-functions.R")
test_res1 <- get_scale_factors_sd(log2sequins_df,thresholdPerMean = 50)
# normalizing using linear regression scaling factors
data_norm1 <- lm_normalize(sampl_data = log2mags, scaleVal_df = test_res1$scaleVal_df)
write.csv(data_norm1, "normalized_tables/coverage_loglmScaling.csv")

input_table <- reorder_df(rbind(data_norm1, c(0,0,0,0,0,0)))
plot_stackbar(plot_df = input_table, file_name = "cov_log_lm.pdf")

# unlogging the data
unlog_loglmnorm <- 2^data_norm1

write.csv(unlog_loglmnorm, "normalized_tables/coverage_unlogloglmScaling.csv")

input_table <- reorder_df(rbind(unlog_loglmnorm, c(0,0,0,0,0,0)))
plot_stackbar(plot_df = input_table, file_name = "cov_unlog_log_lm.pdf")


# NON-LOG LM SCALING
# getting linear regression scaling factors
#source("sip-norm-functions.R")
lm_res <- get_scale_factors_sd(sequins_df,thresholdPerMean = 100)
# normalizing using linear regression scaling factors
data_norm2 <- lm_normalize(sampl_data = df_list$mags, scaleVal_df = lm_res$scaleVal_df)
write.csv(data_norm2, "normalized_tables/cov_lmScaling.csv")

input_table <- reorder_df(data_norm2)
plot_stackbar(plot_df = input_table, file_name = "cov_lm.pdf")


# RATIO NORMALIZED

# coverage(scaffold)/coverage(all_equal_sequins) - should be similar version
# as with RPKM

# finding total of spikings per each sample
sp_eq_sums <- colSums(sequins_df)[-which(colnames(sequins_df) == "rel_conc")]
# adding a row for total sequins to the table with bacterial data
sp_eq_sums <- as.data.frame(t(sp_eq_sums))
data_notnorm <- df_list[["mags"]]
data_notnorm <- rbind(data_notnorm, sp_eq_sums)
rownames(data_notnorm)[nrow(data_notnorm)] <- "Sequins"
# creating a normalization dataframe
sp_eq_sums <- sp_eq_sums[rep(seq_len(nrow(sp_eq_sums)), nrow(data_notnorm)), ]

# normalizing data by dividing with total sum of all sequins in a sample
cov_ratio_df <- data_notnorm/sp_eq_sums
write.csv(cov_ratio_df, "normalized_tables/coverage_ratio.csv")

# plotting normalized data
input_table <- reorder_df(cov_ratio_df)
plot_stackbar(plot_df = input_table, file_name = "cov_ratio.pdf")


# RUVg NORMALIZATION OF COVERAGE
# using untransformed data!
require("RUVSeq")
raw_files_path <- "./stat_files/"
parsed <- parse_bbmap_cov(raw_files_path, sp_meta)
set <- as.matrix(rbind(parsed$mags,parsed$spequins))
spikes <- rownames(set) %in% same_sequins

setRUVg <- RUVg(set, spikes, k=1, isLog = T)
write.csv(setRUVg$normalizedCounts, "normalized_tables/coverage_RUVg.csv")

# plotting normalized data
bac_logic <- rownames(setRUVg$normalizedCounts) %in% rownames(parsed$mags)
ruvg_bac <- as.data.frame(setRUVg$normalizedCounts[bac_logic,])
input_table <- reorder_df(ruvg_bac)
plot_stackbar(plot_df = input_table, file_name = "ruvg_cov_bact.pdf")



















# to see how similar the graphs are
# DATA TRANSFORMATION
# doing log2(x+1) tranformation for the counts
log10sequins_df <- log((sequins_df + 1),10)
log10mags <- log((df_list$mags + 1),10)


# LOG10 LM SCALING
# getting linear regression scaling factors
#source("sip-norm-functions.R")
test_res10 <- get_scale_factors_sd(log10sequins_df,thresholdPerMean = 50)
# normalizing using linear regression scaling factors
data_norm10 <- lm_normalize(sampl_data = log10mags, scaleVal_df = test_res10$scaleVal_df)
write.csv(data_norm10, "normalized_tables/coverage_log10lmScaling.csv")

input_table <- reorder_df(data_norm10)
plot_stackbar(plot_df = input_table, file_name = "cov_log10_lm.pdf")

# unlogging the data
unlog_loglmnorm <- 10^data_norm10

write.csv(unlog_loglmnorm, "normalized_tables/coverage_unloglog10lmScaling.csv")

input_table <- reorder_df(unlog_loglmnorm)
plot_stackbar(plot_df = input_table, file_name = "cov_unlog_log10_lm.pdf")




