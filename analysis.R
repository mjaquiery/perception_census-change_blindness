###################################################
# Change Blindness Experiment – Analysis          #
#                                                 #
# Data source: CSV exported from the jsPsych      #
# experiment (web/experiment.js).                 #
#                                                 #
# Primary analysis:                               #
#   Proportion of correct responses in masked     #
#   vs. unmasked trials.                          #
#                                                 #
# Secondary analysis:                             #
#   Response time (ms) on correct trials in       #
#   masked vs. unmasked conditions.               #
###################################################

# Libraries ---------------------------------------------------------------
library(tidyverse)

# Load data ---------------------------------------------------------------
# Set this to the path of your exported jsPsych CSV file.
data_file <- "data/change_blindness_data.csv"

if (!file.exists(data_file)) {
  stop(
    "Data file not found: ", data_file, "\n",
    "Export your jsPsych data as CSV (the experiment downloads it ",
    "automatically) and update 'data_file'."
  )
}

raw <- read_csv(data_file, show_col_types = FALSE)

# Process data ------------------------------------------------------------
# Keep only experiment trials (rows that have response data).
d <- raw %>%
  filter(!is.na(correct), !is.na(response_time_ms)) %>%
  mutate(
    masked = as.logical(masked),
    correct = as.logical(correct),
    condition = factor(
      ifelse(masked, "masked", "unmasked"),
      levels = c("unmasked", "masked")
    )
  )

cat(sprintf("Loaded %d trials.\n", nrow(d)))

# Descriptive statistics --------------------------------------------------
desc <- d %>%
  group_by(condition) %>%
  summarise(
    n_trials    = n(),
    n_correct   = sum(correct),
    pct_correct = mean(correct) * 100,
    mean_rt_ms  = mean(response_time_ms[correct == TRUE], na.rm = TRUE),
    sd_rt_ms    = sd(response_time_ms[correct == TRUE], na.rm = TRUE),
    .groups = "drop"
  )

cat("\n── Descriptive statistics ───────────────────────────────\n")
print(desc)

# Primary: proportion correct (masked vs. unmasked) -----------------------
ct <- with(d, table(condition, correct))
chi <- chisq.test(ct)

cat("\n── Primary: proportion correct ─────────────────────────\n")
cat(sprintf(
  "  Unmasked: %.1f%%\n  Masked:   %.1f%%\n",
  desc$pct_correct[desc$condition == "unmasked"],
  desc$pct_correct[desc$condition == "masked"]
))
cat(sprintf(
  "  χ²(%d) = %.3f, p = %.4f\n",
  chi$parameter, chi$statistic, chi$p.value
))

# Secondary: response time on correct trials ------------------------------
correct_only <- d %>% filter(correct)
rt_test <- t.test(response_time_ms ~ condition, data = correct_only)

cat("\n── Secondary: response time (correct trials only) ──────\n")
cat(sprintf(
  "  Unmasked: M = %.1f ms, SD = %.1f ms\n  Masked:   M = %.1f ms, SD = %.1f ms\n",
  desc$mean_rt_ms[desc$condition == "unmasked"],
  desc$sd_rt_ms[desc$condition == "unmasked"],
  desc$mean_rt_ms[desc$condition == "masked"],
  desc$sd_rt_ms[desc$condition == "masked"]
))
cat(sprintf(
  "  t(%.1f) = %.3f, p = %.4f\n",
  rt_test$parameter, rt_test$statistic, rt_test$p.value
))

# Visualise ---------------------------------------------------------------

# 1. Proportion correct by condition
p1 <- ggplot(desc, aes(x = condition, y = pct_correct, fill = condition)) +
  geom_col(width = 0.5, colour = "black") +
  geom_text(aes(label = sprintf("%.1f%%", pct_correct)), vjust = -0.5) +
  scale_y_continuous(limits = c(0, 105)) +
  scale_fill_manual(values = c(unmasked = "#3498DB", masked = "#E74C3C")) +
  labs(
    title = "Proportion Correct by Condition",
    x = "Condition",
    y = "% Correct"
  ) +
  theme_light() +
  theme(legend.position = "none")

print(p1)

# 2. Response time on correct trials
p2 <- ggplot(correct_only, aes(x = condition, y = response_time_ms, fill = condition)) +
  geom_boxplot(outlier.colour = NA, alpha = 0.7) +
  geom_jitter(width = 0.15, alpha = 0.4) +
  stat_summary(
    geom = "crossbar", fun = mean, fun.min = mean, fun.max = mean,
    width = 0.4, colour = "black", linewidth = 0.8
  ) +
  scale_fill_manual(values = c(unmasked = "#3498DB", masked = "#E74C3C")) +
  labs(
    title = "Response Time on Correct Trials",
    x = "Condition",
    y = "Response Time (ms)"
  ) +
  theme_light() +
  theme(legend.position = "none")

print(p2)
