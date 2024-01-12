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
# In 'dynamic' trials, these are moving in        #
# straight lines, in 'static' trials they are     #
# stationary.                                     #
# One object per trial alters its trajectory      #
# ('dynamic' trials) or its orientation ('simple' #
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
# Classic change blindness is the 'static'        #
# version of the task. The 'dynamic' version was  #
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
# Dynamic trials' objects follow a trajectory, non-dynamic trials stay still
# Masked trials blip the display off while the change takes place

dt <- d %>%
  mutate(
    complex = bitwAnd(tt, 1),
    dynamic = bitwAnd(tt, 2),
    masked = bitwAnd(tt, 4)
  )


# Filter data -------------------------------------------------------------

# Successful trials only should be analysed
ok <- dt %>% filter(s == T)

# Trial software has a bug that means some trials report Javascript's maxint
# for trial time.
# We limit max time to a minute here.
clean <- ok %>% filter(t < 6e4)

# Final analysis set should only include participants who did
# at least one trial for all trial types
final <- clean %>%
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

# Change blindness is defined as the interaction between masking and complexity.
# We may see main effects and interactions, but the complex:masked interaction
# is what we actually care about.
#
# We want a within-subjects ANOVA because all subjects do all conditions
for_aov <- final %>%
  mutate(
    id = factor(id),
    complex = factor(ifelse(complex, "complex", "simple")),
    dynamic = factor(ifelse(dynamic, "dynamic", "static")),
    masked = factor(ifelse(masked, "masked", "unmasked"))
  )
ezANOVA(
  data = for_aov,
  dv = t,
  wid = id,
  within = c('complex', 'dynamic', 'masked')
)

# Details
# Means for each trial type
for_aov %>%
  group_by(complex, dynamic, masked) %>%
  reframe(mean_cl_normal(t))

# Secondary analysis ------------------------------------------------------

# T-test of complex static masked vs complex static unmasked
# We would expect to see a significant effect here to indicate change blindness
# has occurred.
for_t <- for_aov %>%
  filter(complex == 'complex', dynamic == 'static')
t.test(t ~ masked, data = for_t)

# And same for dynamic trials
# We would expect to see a significant effect here to indicate change blindness
# has occurred.
for_t_dynamic <- for_aov %>% filter(complex == 'complex', dynamic == 'dynamic')
t.test(t ~ masked, data = for_t_dynamic)

# Many participants have missing trial types, making them invalid for
# within-subjects ANOVA. This means that lots of participants need to be
# excluded.
# Another approach is a between subjects analysis on mean t per trial type.
# This gives us a sense of whether the effect pertains in the group as a whole.
by_tt <- clean %>%
  group_by(id, complex, dynamic, masked) %>%
  summarise(t = mean(t), .groups = 'drop') %>%
  mutate(
    id = factor(id),
    complex = factor(ifelse(complex, "complex", "simple")),
    dynamic = factor(ifelse(dynamic, "dynamic", "static")),
    masked = factor(ifelse(masked, "masked", "unmasked"))
  )
ezANOVA(
  data = by_tt,
  dv = t,
  wid = id,
  between = c('complex', 'dynamic', 'masked')
)

