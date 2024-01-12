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

The primary analysis is a within-subjects ANOVA of all successful trials where the response time is less than 1 minute.
We expect to see an interaction between complexity and masking (complex masked trials should take longer than non-complex or non-masked trials).

We also include direct t-tests of complex trials across masking condition separately for dynamic and static trials.
Anyone interested in classic change blindness results only should focus on the t-test on the static data.

