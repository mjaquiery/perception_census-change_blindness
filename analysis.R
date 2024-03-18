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

# Final analysis set should only include participants who did
# at least one trial for all trial types
final <- fixed %>%
  nest(d = -id) %>%
  mutate(ok = map_lgl(d, ~ (unique(.$tt) %>% length()) == 8)) %>%
  filter(ok) %>%
  unnest(cols = d)

# Descriptive statistics --------------------------------------------------

tribble(
  ~statistic, ~value,
  "n_participants", unique(dt$id) %>% length(),
  "mean_trials_pp", dt %>% group_by(id) %>% summarise(n = n()) %>% pull(n) %>% mean(),
  "mean_successful_trials_pp", ok %>% group_by(id) %>% summarise(n = n()) %>% pull(n) %>% mean(),
  "mean_good_trials_pp", clean %>% group_by(id) %>% summarise(n = n()) %>% pull(n) %>% mean(),
  "n_participants_with_all_tts", unique(final$id) %>% length(),
  "mean_good_trials_pp_in_test_set", final %>% group_by(id) %>% summarise(n = n()) %>% pull(n) %>% mean(),
)

# Primary analysis --------------------------------------------------------
#
# T-test of complex orientation masked vs complex orientation unmasked
# We would expect to see a significant effect here to indicate change blindness
# has occurred.
#
# This is a paired t-test on means.
for_t <- fixed %>%
  filter(complex == 'complex', trajectory == 'orientation') %>%
  group_by(id, masked) %>%
  summarise(t = mean(t), .groups = 'drop') %>%
  nest(d = -id) %>%
  mutate(ok = map_lgl(d, ~ nrow(.) == 2)) %>%
  filter(ok) %>%
  unnest(cols = d)
t.test(t ~ masked, data = for_t, paired = T)

# Secondary analysis ------------------------------------------------------

# And same for trajectory trials
# We would expect to see a significant effect here to indicate change blindness
# has occurred.
for_t_trajectory <- fixed %>%
  filter(complex == 'complex', trajectory == 'trajectory') %>%
  group_by(id, masked) %>%
  summarise(t = mean(t), .groups = 'drop') %>%
  nest(d = -id) %>%
  mutate(ok = map_lgl(d, ~ nrow(.) == 2)) %>%
  filter(ok) %>%
  unnest(cols = d)
t.test(t ~ masked, data = for_t_trajectory, paired = T)

# Change blindness is defined as the interaction between masking and complexity.
# We may see main effects and interactions, but the complex:masked interaction
# is what we actually care about.
#
# We want a within-subjects ANOVA because all subjects do all conditions
ezANOVA(
  data = final,
  dv = t,
  wid = id,
  within = c('complex', 'trajectory', 'masked')
)

# Details
# Means for each trial type
final %>%
  group_by(complex, trajectory, masked) %>%
  reframe(mean_cl_normal(t))

# Many participants have missing trial types, making them invalid for
# within-subjects ANOVA. This means that lots of participants need to be
# excluded.
# Another approach is a between subjects analysis on mean t per trial type.
# This gives us a sense of whether the effect pertains in the group as a whole.
by_tt <- fixed %>%
  group_by(id, complex, trajectory, masked) %>%
  summarise(t = mean(t), .groups = 'drop')
ezANOVA(
  data = by_tt,
  dv = t,
  wid = id,
  between = c('complex', 'trajectory', 'masked')
)

