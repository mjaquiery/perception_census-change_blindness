###################################################
# Run a simple ANOVA analysis to determine        #
# whether change blindness occurs in complex      #
# scenes.                                         #
#                                                 #
# Based on an analysis detailed in                #
# anova_output.spv                                #
#                                                 #
# Task description:                               #
# Participants see a screen with 2 (simple)       #
# or 6 (complex) rectangles of different colours. #
#                                                 #
# One object per trial alters its trajectory      #
# ('trajectory' trials) or its orientation        #
# trials). This is the target object that         #
# participants have to click to successfully      #
# complete the trial.                             #
# On 'masked' trials, the objects disappear       #
# while the target object changes. On             #
# 'unmasked' trials, the target object changes    #
# while on screen.                                #
# The scene replays indefinitely until an         #
# answer is collected.                            #
#                                                 #
# The outcome measure is the time taken to        #
# correctly identify the target object.           #
# Trials where a non-target object is selected    #
# are discarded, although it's likely that errors #
# occur with higher frequency on change blindness #
# trials (where complexity is high and changes are#
# masked).                                        #
#                                                 #
# Classic change blindness is the 'orientation'        #
# version of the task. The 'trajectory' version was  #
# developed as a student project by Matt Jaquiery #
# and Ron Chrisley.                               #
#                                                 #
# - matt.jaquiery@dtc.ox.ac.uk                    #
###################################################

# Libraries ---------------------------------------------------------------
renv::restore()
library(tidyverse)
library(ez)
library(bayesplay)

# Load data ---------------------------------------------------------------

d <- read_csv("data/preprocessed.csv")

# Apply trial type information
#
# From source code (index.html:218)
# Complex trials have 6 objects to track, non-complex have 2
# Dynamic trials' objects follow a trajectory, non-trajectory trials stay still
# Masked trials blip the display off while the change takes place

dt <- d %>%
  mutate(
    complex = bitwAnd(tt, 1),
    trajectory = !bitwAnd(tt, 2),
    masked = !bitwAnd(tt, 4)
  ) %>%
  mutate(
    id = factor(id),
    complex = factor(ifelse(complex, "complex", "simple")),
    trajectory = factor(ifelse(trajectory, "trajectory", "orientation")),
    masked = factor(ifelse(masked, "masked", "unmasked"))
  )


# Filter data -------------------------------------------------------------

# Successful trials only should be analysed
ok <- dt %>% filter(s == T)

# Trial software has a bug that means some trials report Javascript's maxint
# for trial time.
# We limit max time to a minute here.
clean <- ok %>% filter(t < 6e4)

# Masked trials take 200ms longer to play per run-through,
# so we subtract 200ms from the first 900ms of the response time
# and then 200ms for each 1600ms thereafter (700+200+700)
fixed <- clean %>%
  mutate(
    t = if_else(masked == "masked" & t > 900, t - 200, t),
    t = if_else(masked == "masked", t - (floor(t / 1600) * 200), t)
  )

# The set for testing is participants who have at least one trial in
# Complex Orientation Masked and at least one trial in
# Complex Orientation Unmasked.
#
# Where participants have more than one trial of the appropriate type,
# the mean of their trials is used.
for_t <- fixed %>%
  filter(complex == 'complex', trajectory == 'orientation') %>%
  group_by(id, masked) %>%
  summarise(t = mean(t), .groups = 'drop') %>%
  nest(d = -id) %>%
  mutate(ok = map_lgl(d, ~ nrow(.) == 2)) %>%
  filter(ok) %>%
  unnest(cols = d)

# Simple quick glance at the data (all categories)
fixed %>% group_by(complex, trajectory, masked) %>% summarise(t = mean(t)) %>% arrange(t)

# Descriptive statistics --------------------------------------------------

tribble(
  ~statistic, ~value,
  "n_participants", unique(dt$id) %>% length(),
  "mean_trials_pp", dt %>% group_by(id) %>% summarise(n = n()) %>% pull(n) %>% mean(),
  "mean_successful_trials_pp", ok %>% group_by(id) %>% summarise(n = n()) %>% pull(n) %>% mean(),
  "mean_good_trials_pp", clean %>% group_by(id) %>% summarise(n = n()) %>% pull(n) %>% mean(),
  "n_participants_with_both_CO_trials", unique(for_t$id) %>% length()
)

# Analysis --------------------------------------------------------
#
# Bayes Factor of complex orientation masked - complex orientation unmasked.
# The null distribution is uniform in the range 0:1000ms difference.
#
# The alternative (expected) distribution is half-normal with mean=1000, sd=2000
#
# 1000ms is the minimum effect size of interest, and 2000 = 3000 - 1000 where
# 3000ms is the expected effect size (and 1000ms is the minimum effect size of interest)
#
# The Bayes Factor will tell us how much more likely it is that masked trials
# take participants about 3s longer to solve than unmasked trials,
# expressed as a ratio of alternative:null.

for_t_diff <- for_t %>%
  pivot_wider(names_from = masked, values_from = t) %>%
  mutate(diff = masked - unmasked)
diffs <- pull(for_t_diff, diff)

# Summarise the data as a likelihood curve
# The SD of the likelihood is the SE of the data.
se = sd(diffs) / sqrt(length(diffs))
d_data <- likelihood(family = 'normal', mean = mean(diffs), sd = se)
plot(d_data)

# minimum effect size of interest
meoi <- 1000

# Define the null distribution
d_h0 <- prior(family = 'uniform', min = 0, max = meoi)
plot(d_h0)
m_h0 <- d_data * d_h0
i_h0 <- integral(m_h0)

# Define the alternate distribution
d_h1 <- prior(family = 'normal', mean = meoi, sd = 3000 - meoi, range = c(meoi, Inf))
plot(d_h1)
m_h1 <- d_data * d_h1
i_h1 <- integral(m_h1)

bf <- i_h1 / i_h0
print(paste("BayesFactor Alternate/Null =", round(bf, 3)))

# We can plot both the individual predictions
p_h0 <- extract_predictions(m_h0)
p_h1 <- extract_predictions(m_h1)
plot(p_h0)
plot(p_h1)
# And a comparison between them
visual_compare(p_h1, p_h0)
visual_compare(p_h1, p_h0, ratio = T)


# Visualise data ----------------------------------------------------------

ggplot(for_t, aes(x = masked, y = t, group = masked)) +
  geom_boxplot(outlier.color = NA, aes(fill = masked, colour = masked), linewidth = 2) +
  geom_point(aes(group = id), alpha = 0.3) +
  geom_line(aes(group = id), alpha = 0.3) +
  stat_summary(linewidth = 2, geom = 'errorbar', fun.data = 'mean_cl_normal', width = 0.1) +
  stat_summary(aes(group = 1), linewidth = 2, geom = 'line', fun = 'mean') +
  scale_x_discrete(limits = rev) +  # flip x axis so unmasked is first
  theme_light()

# vs. minimum effect size of interest
diffs <- for_t %>%
  pivot_wider(names_from = masked, values_from = t) %>%
  mutate(diff = masked - unmasked)

ggplot(diffs, aes(x = diff)) +
  annotate(geom = 'rect', xmin = 1000, xmax = Inf, ymin = 0, ymax = Inf, fill = 'pink') +
  annotate(geom = 'rect', xmin = -Inf, xmax = 1000, ymin = 0, ymax = Inf, fill = 'lightblue') +
  geom_histogram(binwidth = 500) +
  theme_light()
