# Change blindness analysis code 

Data collected in the University of Sussex Perception Census project. 

## Task 

Participants see a screen with 2 (simple) or 6 (complex) rectangles of different colours. 
In 'dynamic' trials, these are moving in straight lines, in 'static' trials they are stationary. One object per trial alters its trajectory ('dynamic' trials) or its orientation ('simple' trials). 
This is the target object that participants have to click to successfully complete the trial. 
On 'masked' trials, the objects disappear while the target object changes. On 'unmasked' trials, the target object changes while on screen. 
The scene replays indefinitely until an answer is collected. 

The outcome measure is the time taken to correctly identify the target object. 
Trials where a non-target object is selected are discarded, although it's likely that errors occur with higher frequency on change blindness trials (where complexity is high and changes are masked). 

Classic change blindness is the 'static' version of the task. The 'dynamic' version was developed as a student project by Matt Jaquiery and Ron Chrisley. 

## Data

Data are not included in this repository.
They will be available separately as part of the Perception Census open data commitment.

They will be a table with one row per trial and have the following columns:

| Variable  | Type | Detail |
|-----------|------|--------|
| id        | integer | participant identifier |
| created_at| datetime| time the record was created |
| tt        | integer | trial type flags: 1 = complex, 2 = dynamic, 4 = masked |
| s         | integer | whether the trial was successful (1 = True) |
| t         | integer | ms taken to submit a response |
| trial_number| integer| trial number for the participant |

## Analysis

The analysis is a Bayesian analysis of complex static trials across masking condition.
The likelihood derived from the observed data is compared against two models:
a null hypothesis model describing effect sizes in the 0-1s range; 
and an alternate hypothesis describing effect sizes in the ~ 1-4s range.

## Write-up 

Some written components are available in the `docs` directory.
