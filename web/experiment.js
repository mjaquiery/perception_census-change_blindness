/**
 * Change Blindness Experiment
 *
 * 20 trials: 10 masked, 10 unmasked (randomly interleaved).
 * Each trial: 10 coloured rectangles on a white canvas for 3 s.
 * Between 1.5 s and 2.5 s a 100 ms change-window occurs:
 *   - Masked trials: all rectangles disappear for 100 ms.
 *   - Unmasked trials: rectangles remain visible.
 *   In both cases, the target rectangle rotates 90° during this window.
 * After 3 s the user must click the rectangle that changed.
 *
 * Uses jsPsych v7 with a custom canvas plugin.
 */

(function () {
  'use strict';

  // ── Constants ────────────────────────────────────────────────────────────────

  /** Canvas dimensions (px) */
  const CANVAS_W = 700;
  const CANVAS_H = 600;

  /** Rectangle dimensions (px) */
  const RECT_W = 80;
  const RECT_H = 40;

  /**
   * Radius of the circumscribed circle for one rectangle.
   * Using the diagonal guarantees the circle fully contains the rectangle
   * at any rotation angle.
   */
  const RECT_R = Math.hypot(RECT_W, RECT_H) / 2; // ≈ 44.7 px

  /** Minimum centre-to-centre distance between any two rectangle circles. */
  const MIN_DIST = RECT_R * 2 + 5; // ≈ 94 px

  /** Minimum distance from a rectangle centre to the canvas edge. */
  const EDGE_PAD = Math.ceil(RECT_R) + 6; // 51 px

  /** Number of rectangles per trial. */
  const N_RECTS = 10;

  /** Maximum total attempts when searching for non-overlapping positions. */
  const MAX_PLACEMENT_ATTEMPTS = 100000;

  /** Total number of trials (half masked, half unmasked). */
  const N_TRIALS = 20;

  /** Observation phase duration (ms). */
  const TRIAL_MS = 3000;

  /** Duration of the blank mask on masked trials (ms). */
  const MASK_MS = 100;

  /** Earliest onset of the change-window within a trial (ms). */
  const MASK_ONSET_MIN = 1500;

  /** Latest onset of the change-window within a trial (ms). */
  const MASK_ONSET_MAX = 2500;

  /** How much the target rectangle rotates (degrees). */
  const ROTATION_DEG = 90;

  /** Ten visually distinct colours, one per rectangle. */
  const COLOURS = [
    '#E74C3C', // red
    '#3498DB', // blue
    '#2ECC71', // green
    '#F1C40F', // yellow
    '#9B59B6', // purple
    '#1ABC9C', // teal
    '#E67E22', // orange
    '#E91E63', // pink
    '#00BCD4', // cyan
    '#8BC34A', // lime
  ];

  // ── Utilities ────────────────────────────────────────────────────────────────

  /** In-place Fisher-Yates shuffle; returns a new array. */
  function shuffle(arr) {
    const a = arr.slice();
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }

  /**
   * Randomly place N_RECTS non-overlapping rectangles inside the canvas,
   * keeping each centre at least EDGE_PAD from every edge.
   * Returns an array of { x, y, colour }.
   */
  function placeRectangles() {
    const shuffledColours = shuffle(COLOURS);
    const placed = [];
    let globalAttempts = 0;

    while (placed.length < N_RECTS && globalAttempts < MAX_PLACEMENT_ATTEMPTS) {
      globalAttempts++;
      const x = EDGE_PAD + Math.random() * (CANVAS_W - 2 * EDGE_PAD);
      const y = EDGE_PAD + Math.random() * (CANVAS_H - 2 * EDGE_PAD);

      const collides = placed.some(
        (r) => Math.hypot(x - r.x, y - r.y) < MIN_DIST,
      );

      if (!collides) {
        placed.push({ x, y, colour: shuffledColours[placed.length] });
      }
    }

    // Fallback: if placement fails (very unlikely), add without collision check.
    while (placed.length < N_RECTS) {
      placed.push({
        x: EDGE_PAD + Math.random() * (CANVAS_W - 2 * EDGE_PAD),
        y: EDGE_PAD + Math.random() * (CANVAS_H - 2 * EDGE_PAD),
        colour: shuffledColours[placed.length],
      });
    }

    return placed;
  }

  /**
   * Test whether canvas point (px, py) lies inside a rectangle
   * centred at (rect.x, rect.y) rotated by angleDeg degrees.
   */
  function hitTest(px, py, rect, angleDeg) {
    const dx = px - rect.x;
    const dy = py - rect.y;
    // Rotate the click point into the rectangle's local frame.
    const rad = -(angleDeg * Math.PI) / 180;
    const lx = dx * Math.cos(rad) - dy * Math.sin(rad);
    const ly = dx * Math.sin(rad) + dy * Math.cos(rad);
    return Math.abs(lx) <= RECT_W / 2 && Math.abs(ly) <= RECT_H / 2;
  }

  /**
   * Draw a single rectangle on ctx, centred at (rect.x, rect.y),
   * rotated by angleDeg degrees.
   * showOutline adds a thin border (used during the response phase).
   */
  function drawRect(ctx, rect, angleDeg, showOutline) {
    ctx.save();
    ctx.translate(rect.x, rect.y);
    ctx.rotate((angleDeg * Math.PI) / 180);
    ctx.fillStyle = rect.colour;
    ctx.fillRect(-RECT_W / 2, -RECT_H / 2, RECT_W, RECT_H);
    if (showOutline) {
      ctx.strokeStyle = 'rgba(0, 0, 0, 0.4)';
      ctx.lineWidth = 2;
      ctx.strokeRect(-RECT_W / 2, -RECT_H / 2, RECT_W, RECT_H);
    }
    ctx.restore();
  }

  // ── Custom jsPsych Plugin ────────────────────────────────────────────────────

  // ParameterType is exposed as a global by the jsPsych 7 CDN bundle.
  // Fall back to a plain object if running in an environment without it.
  // The numeric value 4 corresponds to ParameterType.BOOL in jsPsych 7.
  const _PT =
    typeof ParameterType !== 'undefined' ? ParameterType : { BOOL: 4 };

  /**
   * ChangeBlindnessPlugin
   *
   * Trial parameters:
   *   masked {boolean} – whether a 100 ms blank mask is shown during the
   *                      change-window. Default: false.
   *
   * Trial data recorded:
   *   masked            – condition flag
   *   target_id         – index (0–9) of the rectangle that changed
   *   rect_positions    – JSON array of {x, y} for all rectangles
   *   mask_onset        – ms from trial start to change-window onset
   *                       (present on all trials; mask only shown when masked=true)
   *   mask_offset       – mask_onset + MASK_MS
   *   change_time       – same as mask_onset (rotation happens at window onset)
   *   click_x / click_y – canvas coordinates of the response click/touch
   *   selected_id       – index of the clicked rectangle (null if none hit)
   *   correct           – whether selected_id === target_id
   *   response_time_ms  – ms between end of observation phase and response
   */
  class ChangeBlindnessPlugin {
    constructor(jsPsych) {
      this.jsPsych = jsPsych;
    }

    trial(displayEl, trialConfig) {
      const rects = placeRectangles();
      const targetIdx = Math.floor(Math.random() * N_RECTS);

      // Current rotation angle for each rectangle (degrees).
      const angles = new Array(N_RECTS).fill(0);

      // Random onset for the change-window.
      const changeWindowOnset =
        MASK_ONSET_MIN + Math.random() * (MASK_ONSET_MAX - MASK_ONSET_MIN);
      const changeWindowOffset = changeWindowOnset + MASK_MS;

      let phase = 'display'; // 'display' | 'response'
      let blankScreen = false; // true during the 100 ms mask
      let responseStart = null;

      // ── DOM ──────────────────────────────────────────────────────────────────
      displayEl.innerHTML = `
        <canvas id="cb-canvas"
                width="${CANVAS_W}"
                height="${CANVAS_H}"
                style="cursor:default;">
        </canvas>`;

      const canvas = document.getElementById('cb-canvas');
      const ctx = canvas.getContext('2d');

      // ── Drawing ──────────────────────────────────────────────────────────────
      const redraw = () => {
        ctx.clearRect(0, 0, CANVAS_W, CANVAS_H);
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);

        if (!blankScreen) {
          const outline = phase === 'response';
          rects.forEach((r, i) => drawRect(ctx, r, angles[i], outline));
        }

        if (phase === 'response') {
          ctx.save();
          ctx.fillStyle = 'rgba(20, 20, 20, 0.75)';
          ctx.font = 'bold 18px sans-serif';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'top';
          ctx.fillText(
            'Which rectangle changed? Click to select.',
            CANVAS_W / 2,
            12,
          );
          ctx.restore();
        }
      };

      // ── Timers ───────────────────────────────────────────────────────────────

      // Change-window: rotate target rectangle; blank screen if masked.
      const changeTimer = setTimeout(() => {
        angles[targetIdx] = (angles[targetIdx] + ROTATION_DEG) % 360;

        if (trialConfig.masked) {
          blankScreen = true;
          redraw();
          setTimeout(() => {
            blankScreen = false;
            redraw();
          }, MASK_MS);
        } else {
          redraw();
        }
      }, changeWindowOnset);

      // End of observation phase → switch to response mode.
      const endTimer = setTimeout(() => {
        phase = 'response';
        canvas.style.cursor = 'pointer';
        responseStart = performance.now();
        redraw();
      }, TRIAL_MS);

      // ── Response handler ──────────────────────────────────────────────────────
      const onInteract = (e) => {
        if (phase !== 'response') return;
        e.preventDefault();

        // Map client coordinates to canvas coordinates (handles CSS scaling).
        const bRect = canvas.getBoundingClientRect();
        const scaleX = CANVAS_W / bRect.width;
        const scaleY = CANVAS_H / bRect.height;
        const src = e.touches ? e.touches[0] : e;
        const cx = (src.clientX - bRect.left) * scaleX;
        const cy = (src.clientY - bRect.top) * scaleY;

        // Determine which rectangle (if any) was clicked.
        let hit = null;
        for (let i = 0; i < rects.length; i++) {
          if (hitTest(cx, cy, rects[i], angles[i])) {
            hit = i;
            break;
          }
        }

        // Only end the trial when the user clicks on a rectangle.
        if (hit === null) return;

        canvas.removeEventListener('click', onInteract);
        canvas.removeEventListener('touchstart', onInteract);
        clearTimeout(changeTimer);
        clearTimeout(endTimer);

        const rt = Math.round(performance.now() - responseStart);

        this.jsPsych.finishTrial({
          masked: trialConfig.masked,
          target_id: targetIdx,
          rect_positions: JSON.stringify(
            rects.map((r) => ({ x: Math.round(r.x), y: Math.round(r.y) })),
          ),
          mask_onset: Math.round(changeWindowOnset),
          mask_offset: Math.round(changeWindowOffset),
          change_time: Math.round(changeWindowOnset),
          click_x: Math.round(cx),
          click_y: Math.round(cy),
          selected_id: hit,
          correct: hit === targetIdx,
          response_time_ms: rt,
        });
      };

      canvas.addEventListener('click', onInteract);
      canvas.addEventListener('touchstart', onInteract, { passive: false });

      // Initial draw.
      redraw();
    }
  }

  ChangeBlindnessPlugin.info = {
    name: 'change-blindness',
    parameters: {
      masked: { type: _PT.BOOL, default: false },
    },
  };

  // ── Experiment setup ─────────────────────────────────────────────────────────

  const jsPsych = initJsPsych({
    on_finish() {
      jsPsych.data.get().localSave('csv', 'change_blindness_data.csv');
    },
  });

  // Balanced, randomised trial list: 10 masked + 10 unmasked.
  const trialList = shuffle([
    ...Array(N_TRIALS / 2).fill(true),
    ...Array(N_TRIALS / 2).fill(false),
  ]).map((masked) => ({
    type: ChangeBlindnessPlugin,
    masked,
  }));

  const timeline = [
    // ── Welcome / instructions ──
    {
      type: jsPsychHtmlButtonResponse,
      stimulus: `
        <div class="cb-instructions">
          <h2>Change Blindness Experiment</h2>
          <p>In each trial you will see <strong>10 coloured rectangles</strong>
             on a white canvas for <strong>3 seconds</strong>.</p>
          <p>At some point during the trial <strong>one rectangle will rotate
             90°</strong>. On some trials the display will briefly go blank
             at the moment of the change.</p>
          <p>After 3 seconds you will be asked to
             <strong>click the rectangle that rotated</strong>.
             Click directly on a rectangle to register your answer.</p>
          <p>There will be <strong>${N_TRIALS} trials</strong> in total.
             Please respond as accurately as you can.</p>
        </div>`,
      choices: ['Begin'],
    },

    // ── Experiment trials ──
    ...trialList,

    // ── Debrief ──
    {
      type: jsPsychHtmlButtonResponse,
      stimulus: `
        <div class="cb-instructions" style="text-align:center;">
          <h2>Thank you!</h2>
          <p>You have completed all ${N_TRIALS} trials.</p>
          <p>Click the button below to download your results as a CSV file.</p>
        </div>`,
      choices: ['Download Results'],
    },
  ];

  jsPsych.run(timeline);
})();
