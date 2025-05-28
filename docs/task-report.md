## Change blindness task
> Contributors: Jaquiery

People routinely fail to notice that changes have occurred within a visual scene if they do not perceive the changes occurring, a phenomenon known as ‘change blindness’ (Simons and Levin, 1998; Rensink et al, 1997).
Typical lab-based change blindness studies use static stimuli and require participants to identify simple changes such as alterations in stimulus orientation or scene composition (Hughes et al, 2012; Lyyra et al, 2014; Gaspar et al, 2013).
Changes are detected when the transients (moment-to-moment variations) accompanying a change are registered and prompt an explicit comparison between a stored representation of a stimulus and its current presentation (Simons and Ambinder, 2005; Mitroff et al, 2004).
Here, the the 'flicker' change blindness paradigm (Rensink et al, 1997) is extended to include moving stimuli where the change to be detected is a change in the trajectory of the target stimulus.

Participants completed a total of 20 trials. 
In 30% of the trials, the presented display consists of 2 rectangles, while in the remaining 70% of the trials the presented display consists of 5 rectangles. 
Half of the trials contain a change in movement trajectory and the other half contain a change in orientation. 
What change occurs on a specific trial is allocated randomly and participants are not told which type of change will occur. 
The stimulus displays prior and after the change are presented for 700ms each. On half of the trials, the switch from the initial display to the changed display is interrupted by a mask (a blank screen) presented for 200ms.
On the other half of the trials, there is no interruption between the initial and changed displays.
A screenshot of the task screen and a schematic of the structure of each trial is shown in Fig 1.

![left) Screenshot of the 700x700 pixel working area of the screen showing rectangles of random colours (selected from an approved region of colour-space) which moved in straight lines through the working area. After 700ms one of the rectangles would alter either its orientation or its trajectory by 90° or 270°. The task for the participants was to identify which of the rectangles had undergone this change. In the simple scene condition only two rectangles were presented; the complex scene condition presented six rectangles as shown. right) ‘Flicker’ paradigm procedure. The initial scene (A) was displayed for 700ms, then a mask was put up for 200ms (masked condition) or 0ms (unmasked condition) before the initial scene was replaced with the altered scene (A’). The altered scene was displayed for 700ms and then masked and reverted to the initial scene. The process was repeated until the participant generated a response.](img/figure1.png)

### Results 

Analysis conducted as per the pre-registered plan, using a version of the pre-registered script amended to change the path of the data file and to account for the identity column having a different name in the full data file compared to the sample data file.

Analysis was restricted to the traditional demonstration of change blindness, removing data from trials where the rectangles were moving or where there were only two rectangles. 
Participants' average increase in response time from unmasked to masked trials was 3841.116ms, with a standard deviation of 3817.032ms and a 95% confidence interval of [3752.971, 3929.261]ms. 

The response times for masked trials (mean 6000.932ms, sd 3957.22ms) were substantially greater than those for unmasked trials  (mean 2159.816ms, sd 2256.264ms). 
The average response time for masked trials was about three times longer than the average response time for unmasked trials.
This observation, that masked trials take substantially longer than unmasked trials, demonstrates the change blindness phenomenon described in the literature.

![Histogram of differences in response times between trials (unmasked - masked). The data are split into 500ms bins, and the count represents the number of participants whose response time difference falls within that bin. The divide between blue and pink background is set at 1000ms, the prior prediction for the minimum effect size of interest as derived from the literature and previous iterations of this experiment conducted on undergraduates.](img/figure2.png)

### References

Gaspar JG, Neider MB, Simons DJ, McCarley JS, Kramer AF. Change Detection: Training and Transfer. PLOS ONE. 2013 Jun 28;8(6):e67781.

Hughes HC, Caplovitz GP, Loucks RA, Fendrich R. Attentive and Pre-Attentive Processes in Change Detection and Identification. PLOS ONE. 2012 Aug 16;7(8):e42851.

Lyyra P, Mäkelä H, Hietanen JK, Astikainen P. Implicit Binding of Facial Features During Change Blindness. PLOS ONE. 2014 Jan 30;9(1):e87682. 

Mitroff SR, Simons DJ, Levin DT. Nothing compares 2 views: Change blindness can occur despite preserved access to the changed information. Percept Psychophys. 2004 Nov;66(8):1268–81. 

Rensink RA, O’Regan JK, Clark JJ. To See or not to See: The Need for Attention to Perceive Changes in Scenes. Psychol Sci. 1997 Sep 1;8(5):368–73. 

Simons DJ, Levin DT. Failure to detect changes to people during a real-world interaction. Psychon Bull Rev. 1998 Dec;5(4):644–9.

Simons DJ, Ambinder MS. Change Blindness Theory and Consequences. Curr Dir Psychol Sci. 2005 Feb 1;14(1):44–8. 
