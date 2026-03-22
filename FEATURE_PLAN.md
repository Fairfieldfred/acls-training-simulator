# ACLS Training Simulator — Optimization & Feature Plan

**Date:** 2026-03-21
**Reviewed by:** B (planning session with KingFred)

---

## 1. Current State Assessment

### What's working well
- Core simulation loop (CPR, defibrillation, meds, reversible causes)
- Two training modes (timing vs. protocol)
- ECG rendering via fl_chart with animated scrolling
- Performance scoring on results screen
- Keyboard shortcuts (C/B/Space)

### Critical gaps
1. **No medication timing enforcement** — you can give epi at 30s, then again at 60s. Real ACLS requires 3–5 minute intervals. Zero feedback on this.
2. **No countdown timer for "next epi due"** — the most used clinical prompt in a real code. Missing entirely.
3. **Rhythm changes are random coin-flips** — not protocol-driven. Shocking VF changes rhythm to PEA by pure random chance, not based on correct shock timing and CPR cycle completion.
4. **Only 5 rhythms** — missing sinus bradycardia, SVT, stable/unstable VT, torsades, A-fib, AVNRT, AVRT, junctional, idioventricular, heart blocks (1°, 2° Mobitz I/II, 3°).
5. **No tachycardia or bradycardia algorithms** — ACLS covers far more than just pulseless arrest. Stable/unstable distinction, cardioversion vs. adenosine vs. beta-blocker decisions are untested.
6. **ECG tracings are oversimplified** — pVT looks like smooth sine waves. Real pVT has beat-to-beat variation, axis shifts. Asystole should occasionally show P-waves (AIVR pattern). No T-wave inversions, delta waves, or ST changes on the NSR for post-ROSC scenarios.
7. **No event log** — no record of what happened when. Debrief is impossible without a timestamped timeline.
8. **No rhythm-change-on-medication timing** — amiodarone after 3rd shock should probabilistically convert VF; magnesium should convert torsades. Currently only epi has any effect.
9. **No post-ROSC care** — after achieving ROSC, nothing happens. Real ACLS continues with post-cardiac arrest care (target BP, O2 sat, 12-lead, cath lab decision).
10. **No multi-lead ECG option** — single-lead monitor is fine for beginners but advanced users need to practice 12-lead interpretation.

---

## 2. Medication Timing System (Priority #1 — KingFred's specific request)

### 2A. Medication Cooldown Timers

Each medication must have enforced timing rules matching 2025 AHA guidelines:

| Medication | Min Interval | Rule |
|-----------|-------------|------|
| Epinephrine | 3 min (180s) | Every 3–5 min during cardiac arrest |
| Amiodarone 1st dose | After 3rd shock | 300mg first dose |
| Amiodarone 2nd dose | After 5th shock or 5 min after 1st | 150mg |
| Lidocaine | After 3rd shock (if no amio given) | Cannot mix with amiodarone |
| Magnesium | No repeat in same arrest (generally) | Only for torsades |
| Atropine | 3–5 min, max 3mg total | Bradycardia only |

### 2B. Medication Timing UI

**Add to the medication panel:**
- Each medication button shows a cooldown overlay when not yet available:
  - Grayed out + "Available in: 2:34" countdown
  - Green pulse animation when the medication window opens ("Epi due now!")
- **Epinephrine timer widget**: A dedicated prominent countdown that shows:
  - "⏱ Next Epi: 2:45" (counting down, red when < 30s, green when due)
  - "⚠️ Epi overdue" flashing when > 5 min since last dose
- **Amiodarone unlock**: Button is locked until 3rd shock is delivered, with "Locked: needs 3 shocks (have: 1)" tooltip
- **Early administration warning**: If a provider attempts epi before 3 min, show a warning dialog:
  "⚠️ Epinephrine given too early (2:12 since last dose). AHA recommends 3–5 min intervals. Administer anyway?"
  Options: [Administer Anyway] [Cancel]
  — If they proceed, it's logged as an error in the event log and reduces performance score.

### 2C. Rhythm-Change-After-Medication Logic

Replace the current random coin-flip with protocol-driven state transitions:

**Epinephrine:**
- Given during VF/pVT: no direct rhythm conversion, but boosts defibrillation success probability by 15% per subsequent shock
- Given during PEA/asystole: 8% chance of converting to an organized rhythm (sinus, junctional, AIVR) per dose, after correct CPR cycle
- Given outside 3–5 min window: reduced effect probability by 50%

**Amiodarone 300mg (after 3rd shock):**
- Given correctly: increases probability of VF→ROSC from next shock from 25% to 45%
- Given before 3rd shock: no additional benefit, logged as protocol deviation

**Amiodarone 150mg (2nd dose, after 5th shock or 5 min):**
- Stacks with 1st dose: VF→ROSC probability from next shock: 55%

**Lidocaine (alternative, if no amio):**
- Similar effect to amiodarone but slightly lower efficacy (VF→ROSC: 35%)
- If given after amiodarone: warn "Lidocaine + amiodarone: increased proarrhythmic risk"

**Magnesium:**
- Scenario-specific: only effective if rhythm is torsades de pointes
- In torsades: 70% chance of converting to NSR after 2 min

**CPR cycle requirement:**
- Rhythm changes (from medication effect OR shock) should only evaluate AFTER a full 2-minute CPR cycle completes
- This is the #1 ACLS teaching point — shock → immediate CPR → check rhythm at 2 min

### 2D. Shock Timing Rules

- Shock should pause CPR for rhythm analysis (2s delay, already implemented)
- After shock: mandatory CPR cycle (2 min) before next rhythm check
- The "Check Rhythm" action should be disabled until 2 min of post-shock CPR is complete (in protocol mode)
- Show a "CPR Cycle" progress bar (0–2 min) after each shock

---

## 3. ECG Tracing Improvements

### 3A. New Rhythms to Add

**Shockable:**
- `vf` — Ventricular Fibrillation (exists, improve waveform)
- `pvt` — Pulseless V-Tach (exists, improve)
- `torsades` — Torsades de Pointes: sinusoidal twisting QRS axis (NEW)

**Non-shockable pulseless:**
- `pea` — PEA (exists)
- `asystole` — Asystole (exists, add occasional P-wave variant)
- `aivr` — Accelerated Idioventricular Rhythm (NEW — common post-ROSC)

**Bradycardias (pulsed):**
- `sinusBradycardia` — Sinus Bradycardia < 50 bpm (NEW)
- `junctional` — Junctional Rhythm ~40–60 bpm (NEW)
- `avBlock1` — 1st Degree AV Block: prolonged PR (NEW)
- `avBlock2Mobitz1` — Wenckebach: progressively lengthening PR then dropped beat (NEW — hardest to render, high value)
- `avBlock2Mobitz2` — Mobitz II: fixed PR, sudden dropped beats (NEW)
- `avBlock3` — Complete Heart Block: P-waves and QRS totally dissociated (NEW)

**Tachycardias (pulsed):**
- `sinusTach` — Sinus Tachycardia: like NSR but 100–150 bpm (NEW)
- `svt` — SVT/AVNRT: narrow complex, 150–220 bpm, no visible P-waves (NEW)
- `afib` — Atrial Fibrillation: irregularly irregular, no P-waves, fibrillatory baseline (NEW)
- `aflutter` — Atrial Flutter: sawtooth flutter waves at 300 bpm, 2:1 or 4:1 block (NEW)
- `vtach` — Ventricular Tachycardia with pulse: wide complex, 150–250 bpm (NEW)

### 3B. ECG Waveform Improvements

**VF:** Current implementation (random noise ±1.0) is acceptable but add:
- Coarse VF (high amplitude) vs fine VF (low amplitude) distinction
- Amplitude degrades over time without defibrillation (fine VF = harder to shock)
- Add slight periodicity to make it look more like real VF (not pure noise)

**pVT:** Current smooth sine is too clean. Improve with:
- Beat-to-beat amplitude variation (±20%)
- Slight axis shifts per beat (QRS morphology varies)
- No visible P-waves

**Torsades:** Sinusoidal twisting pattern — QRS amplitude waxes and wanes with gradual axis rotation over ~10–15 beats. This is the most visually distinctive rhythm.

**Sinus patterns (NSR, sinus Brady, sinus tach):** Improve current pattern:
- Better P-wave morphology (current P is too smooth/large)
- Proper PR interval (0.12–0.20s)
- Distinct QRS (sharp Q dip, tall narrow R, S wave)
- T-wave should be asymmetric (slow rise, fast fall)
- ST segment should be flat/isoelectric

**AV Blocks:**
- Mobitz I: each beat has slightly longer PR until one P-wave fires with no QRS
- Mobitz II: consistent PR, then sudden dropped QRS (no warning)
- 3rd degree: P-waves march out at atrial rate (~70), QRS march out at ventricular rate (~35), completely independent

**AFib:** Irregular RR intervals (vary ±30%), absent P-waves, fine fibrillatory baseline between QRS complexes

**AFL:** Sawtooth flutter waves (inverted in leads II, III, aVF pattern), QRS every 2nd or 4th flutter wave

### 3C. Multi-Lead Selector (Optional Advanced Mode)

For the simulation screen, add a "Lead" dropdown: Lead I, II, III, aVR, aVL, aVF, V1, V6.
Each lead shows the same rhythm but with appropriate amplitude inversion/scaling:
- Lead II: best for P-waves and inferior MI pattern
- V1: best for RBBB, SVT differentiation
- aVR: inverted relative to Lead II

This is advanced — lower priority, but high educational value.

---

## 4. New Scenarios

### Shockable Arrest Scenarios (expand existing)
- **VF Cardiac Arrest** (exists — beginner)
- **Pulseless V-Tach** (exists as refractory VF — intermediate)
- **Torsades de Pointes** (NEW — intermediate): precipitated by long QT. Correct treatment is magnesium, not amiodarone.
- **Refractory VF — Double Sequential Defibrillation** (NEW — advanced): VF not responding after 5+ shocks

### Non-Shockable Arrest Scenarios
- **PEA Arrest** (exists — intermediate)
- **Asystole** (exists — beginner)
- **PEA from Tension Pneumothorax** (NEW — advanced): correct H&T identification teaches needle decompression
- **PEA from Pulmonary Embolism** (NEW — advanced): massive PE, considers thrombolytics

### Tachycardia Scenarios (NEW — entire algorithm branch)
- **Stable SVT**: Vagal maneuvers → adenosine 6mg → adenosine 12mg → rate control
- **Unstable SVT** (with hypotension): synchronized cardioversion 50–100J
- **Stable Wide Complex Tachycardia** (VT with pulse): adenosine → amiodarone → cardioversion
- **Unstable VT**: Synchronized cardioversion 100–200J
- **Atrial Fibrillation** (stable): rate vs rhythm control decision
- **Unstable AFib**: Cardioversion decision (anticoagulation first if > 48h!)
- **Atrial Flutter**: 4:1 block, rate control, cardioversion

### Bradycardia Scenarios (NEW — entire algorithm branch)
- **Symptomatic Sinus Bradycardia**: Atropine 0.5mg → repeat → transcutaneous pacing
- **Complete Heart Block**: Transcutaneous pacing (atropine often ineffective)
- **Mobitz II**: Transcutaneous pacing (atropine contraindicated!)
- **Junctional Bradycardia**: Atropine, pacing

---

## 5. New Features

### 5A. Event Log / Timeline (High Priority)
A real-time timestamped log of every action during a simulation.

**Implementation:**
- Add `EventLog` class with entries: `{ int timeSeconds, String action, String category, bool isError }`
- Categories: CPR, Medication, Shock, Airway, Assessment, Error
- Display as a scrolling list on the right side of the simulation screen (collapsible on smaller screens)
- Color coded: green = correct, yellow = suboptimal, red = protocol error
- Examples:
  - `00:00 — Scenario started (VF)`
  - `00:08 — Rhythm analyzed`
  - `00:22 — ⚡ Shock #1 delivered (200J) — VF persists`
  - `00:23 — CPR resumed`
  - `01:58 — ⚠️ Epinephrine given too early (1:58 — should be ≥ 3:00)`
  - `02:18 — ⚡ Shock #2 delivered (200J) — VF persists`
  - `04:30 — Epinephrine 1mg IV ✓`
  - `06:45 — ⚡ Shock #3 delivered (200J)`
  - `06:46 — Amiodarone 300mg ✓ (given after 3rd shock)`
  - `08:52 — ROSC achieved!`

**The event log is shown on the Results screen** as a complete debrief timeline. This is the most educationally valuable feature missing from the app.

### 5B. Tachycardia Algorithm Screen (New Treatment Path)
When a tachycardia scenario is selected, the simulation screen shows:
- Rate indicator prominently (150 bpm, wide complex, etc.)
- "Is the patient stable or unstable?" decision button
- Stable path: stepwise medication tree (vagal maneuvers, adenosine, etc.)
- Unstable path: synchronized cardioversion setup (energy selector, sync mode)
- "SYNC" button that prevents unsynchronized shock (critical safety teaching)

### 5C. Bradycardia Algorithm Screen (New Treatment Path)
- "Is the patient symptomatic?" decision
- Atropine button (0.5mg, max 3mg = 6 doses, each with timer)
- Transcutaneous pacing button → shows pacing capture success/failure
- "Dopamine/Epinephrine infusion" for refractory cases

### 5D. Post-ROSC Care Screen
After achieving ROSC, instead of immediately ending the simulation, show a post-ROSC management phase:
- Target O2 sat: 94–99% (avoid hyperoxia)
- Target systolic BP > 90 mmHg
- 12-lead ECG interpretation hint (ST elevation? → cath lab)
- Temperature management (TTM) decision
- Options: O2 titration, vasopressors (norepinephrine, dopamine), 12-lead ECG, transfer to ICU
- Scoring: post-ROSC care quality factors into final score

### 5E. Compression Rate Feedback (Enhance Existing)
- Current: compressionRate computed but unclear how it's displayed
- Add: a real-time compression rate gauge in the CPR panel (bpm display, green 100–120, yellow outside range)
- Add: metronome mode — optional audio/visual click at 110 bpm to guide compression rate
- Add: "No-flow ratio" tracking — what % of time was no CPR being performed (pauses > 10s = logged)

### 5F. Scenario Editor / Custom Scenarios
A simple form to build a custom scenario:
- Select initial rhythm
- Set patient weight (for weight-based dosing)
- Set reversible causes present (which H&Ts are the answer)
- Set difficulty modifiers (how many shocks before ROSC, medication requirements)
- Save to local storage (localStorage for web)

### 5G. Reference Panel (In-Sim Quick Reference)
A collapsible side panel or bottom sheet showing:
- Current algorithm flowchart (VF/pVT path, PEA/asystole path, tachy, brady)
- H's and T's checklist reference
- Drug dosing quick-reference card
- AHA 2025 key updates summary

### 5H. Progress / Statistics Dashboard
A home screen addition tracking historical performance across sessions:
- Total scenarios completed
- ROSC rate (%)
- Average time to first shock
- Average time to first epi
- Most improved area
- Weak areas (e.g., "Medication timing: 3.2 min avg vs. 3–5 min target")
- Store in browser localStorage for web

### 5I. Quiz Mode
A separate mode (not simulation) that presents:
- Static ECG strip → "What rhythm is this?" (multiple choice)
- Clinical scenario → "What do you do next?" (multiple choice)
- Drug dosing questions → fill in dose/route
- Score tracked, spaced repetition for wrong answers
- 20 built-in questions covering all AHA algorithms

---

## 6. UX Improvements

### 6A. Responsive Layout
Current layout likely stacks vertically on all screens. For web:
- Wide layout (> 900px): ECG + patient vitals on left, action panels on right (2-column)
- Medium (600–900px): stacked but panels collapsed/expandable
- Narrow (< 600px): single column, panels in tabs/accordion

### 6B. ROSC Animation
When ROSC is achieved, show a brief satisfying animation:
- ECG transitions smoothly from arrest rhythm to NSR (not instant snap)
- Patient color changes (gray → pink)
- "ROSC ACHIEVED" banner with confetti/pulse animation
- Vitals populate one by one (HR 75, BP 110/70, SpO2 95%)

### 6C. Simulation Screen Timer Redesign
- Code timer: larger, more prominent, center-top
- Epi countdown: separate dedicated widget, high visibility
- CPR cycle timer: progress arc around CPR button
- "Time since last shock": shown in defibrillator panel

### 6D. Dark Mode (Medical Monitor Aesthetic)
- Option for dark theme — black background, green accents (like real defibrillator monitors)
- The ECG is already black/green — rest of the UI should match in dark mode
- Store preference in localStorage

### 6E. Better Home Screen
- Category cards instead of flat list: Arrest Algorithms / Tachycardia Algorithms / Bradycardia Algorithms / Quiz Mode
- Difficulty badges on each scenario
- "Continue from last session" if a session was paused
- Version/guidelines badge ("2025 AHA Guidelines")

### 6F. Results Screen Improvements
- Show event timeline (from 5A)
- Comparison to "ideal run" benchmarks
- Specific feedback per error ("You gave epinephrine at 1:58 — too early by 1:02")
- Share/export results as PDF or image for portfolio/education records
- "Retry" button (restarts same scenario)
- "Next difficulty" button (suggests harder scenario)

---

## 7. Implementation Priority

### Phase 1 — Medication Timing (KingFred's top request)
1. Medication timing model (cooldowns, eligibility rules)
2. Medication timer UI (cooldown overlays, epi countdown)
3. Early/late administration warnings with event logging
4. CPR-cycle-gated rhythm changes (2-min rule)
5. Protocol-driven ROSC probability based on medications given correctly

### Phase 2 — ECG Improvements
1. Improve NSR, VF, pVT waveforms
2. Add torsades, sinus brady, sinus tach
3. Add SVT, AFib
4. Add AV blocks (1°, Mobitz II, 3rd degree — most clinically important)
5. Add AIVR

### Phase 3 — New Scenarios
1. Torsades de Pointes scenario
2. Symptomatic Bradycardia scenarios (3°AVB, Mobitz II)
3. Unstable Tachycardia scenarios (SVT, VT)
4. PEA from PE / tension pneumo

### Phase 4 — Event Log & Debrief
1. EventLog class + real-time logging throughout service
2. Event log display panel in simulation screen
3. Results screen debrief timeline

### Phase 5 — New Feature Screens
1. Post-ROSC care screen
2. Reference panel (collapsible)
3. Progress dashboard (localStorage)
4. Quiz mode

### Phase 6 — UX & Polish
1. Responsive web layout
2. ROSC animation
3. Timer redesign
4. Dark mode
5. Home screen redesign

---

*Last updated: 2026-03-21*
