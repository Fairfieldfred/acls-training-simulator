You are implementing the features in FEATURE_PLAN.md for the ACLS Training Simulator Flutter web app at /Users/macmini/Dev/acls-training-simulator.

Read FEATURE_PLAN.md fully first. Then read ALL existing source files carefully before making any changes:
- lib/main.dart
- lib/models/ (all models)
- lib/services/simulation_service.dart
- lib/screens/ (all screens)
- lib/widgets/ (all widgets)

Work phase by phase. Commit after each phase. When a phase is complete, immediately start the next.

---

## PHASE 1 — Medication Timing System

### 1A. Medication timing model
- Create lib/models/medication_timing_model.dart:

  class MedicationTiming {
    final String medicationName;
    final int minIntervalSeconds;       // minimum seconds between doses
    final int? maxDoses;                // null = unlimited
    final int? requiresShockCount;      // null = no shock requirement
    final bool requiresNoAmiodarone;    // for lidocaine (can't mix)
    final String? requiresRhythm;       // 'torsades' for magnesium, null = any
    final String clinicalNote;          // shown in warning dialogs
  }

  class MedicationDoseRecord {
    final String medicationName;
    final int timeSeconds;
    final bool wasEarly;           // given before minInterval elapsed
    final bool wasEligible;        // met all eligibility criteria
  }

  class MedicationEligibility {
    final bool canAdminister;
    final String? reason;                   // why not eligible (if canAdminister == false)
    final int? secondsUntilEligible;        // how long until eligible
    final bool isOverdue;                   // past the max recommended window
    final String? overdueMessage;
  }

Add to lib/models/medication_model.dart: a `timing` getter on Medication that returns a MedicationTiming for each med.

Timing rules (2025 AHA):
- Epinephrine: minInterval=180s (3 min), no max doses, no shock requirement, isOverdue if > 300s (5 min) since last dose
- Amiodarone 1st dose: requiresShockCount=3, minInterval=0 (can give right after 3rd shock), maxDoses=1
- Amiodarone 2nd dose: requiresShockCount=5 OR (300s after 1st dose), maxDoses=1, requiresNoAmiodarone=false (it IS amiodarone)
- Lidocaine: requiresShockCount=3, requiresNoAmiodarone=true (cannot give if amiodarone already given)
- Magnesium: requiresRhythm='torsades' (only for torsades), maxDoses=1
- Atropine: minInterval=180s, maxDoses=6 (max 3mg total, 0.5mg each), only for bradycardia not arrest

### 1B. MedicationEligibilityService
- Create lib/services/medication_eligibility_service.dart:

  class MedicationEligibilityService {
    MedicationEligibility checkEligibility(
      Medication med,
      List<MedicationDoseRecord> doseHistory,
      int currentShockCount,
      int codeTimeSeconds,
      ECGRhythm currentRhythm,
    )
  }

  Logic:
  - Look up last dose of this med in doseHistory
  - Check shock count requirement
  - Check interval requirement
  - Check rhythm requirement
  - Check max doses
  - Check amiodarone conflict for lidocaine
  - Return MedicationEligibility with clear reason string

### 1C. Update SimulationService
Replace the existing _medicationsGiven: List<String> with:
  _doseHistory: List<MedicationDoseRecord>
  (keep a getter medicationsGiven for backward compat that maps to display strings)

Add to SimulationService:
  - MedicationEligibilityService _eligibilityService
  - MedicationEligibility getMedicationEligibility(Medication med)
  - int? get secondsSinceLastEpi (computed from _doseHistory)
  - bool get isEpiOverdue (> 300s since last epi and arrest is ongoing)
  - int? get nextEpiDueSeconds (seconds until 3-min mark)

In administerMedication():
  - Check eligibility first
  - Record MedicationDoseRecord with wasEarly and wasEligible
  - If wasEarly: still allow but log as error (user confirmed via dialog in UI)
  - Improve rhythm-change probability based on correct medication timing:
    - Epi given at correct interval: boosts next shock ROSC probability by 15%
    - Epi given too early: no boost
    - Amiodarone given correctly after 3rd shock: boosts next shock ROSC probability to 45%
    - Amiodarone 2nd dose given correctly: boosts to 55%
    - Lidocaine given correctly: boosts to 35%
    - Magnesium in torsades: 70% conversion after 120s delay (use Future.delayed)

Add CPR cycle enforcement:
  - Track _postShockCprSeconds (resets to 0 after each shock, counts up)
  - bool get cprCycleComplete => _postShockCprSeconds >= 120
  - analyzeRhythm() should check if cprCycleComplete; if not and isProtocolMode, show warning

### 1D. Update MedicationPanel widget
- Update lib/widgets/medication_panel.dart:
  - Each medication button:
    - If not eligible: show grayed out with reason tooltip + countdown timer overlay "Available in: 2:34"
    - If eligible: normal color, pulse animation if it's the "recommended now" time
    - If overdue (epi): flash red border "Epi OVERDUE"
  - Add dedicated EpiTimer widget at top of panel:
    - Large countdown: "Next Epi in: 2:45"
    - Color: gray (before first epi), green (counting down to 3 min), red (overdue)
    - Shows "Epi Due NOW" with pulsing green when in the 3–5 min window
  - Early administration: when user taps a medication that is eligible but was given early OR isn't fully eligible, show a ConfirmationDialog:
    "⚠️ Protocol Advisory: [reason]. Administer anyway?"
    If confirmed: administer and log as wasEarly=true
    If cancelled: do nothing

### 1E. CPR Cycle Progress in Defibrillator Panel
- Update lib/widgets/defibrillator_panel.dart:
  - After a shock is delivered, show a CPR cycle progress bar (0–120s, 2 minutes)
  - "Analyze Rhythm" button disabled and shows countdown "Check rhythm in: 1:34" until cprCycleComplete
  - In protocol mode: analyze rhythm after 2-min CPR automatically prompts user

Commit: "feat: Phase 1 — medication timing system with eligibility checking, epi countdown, CPR cycle enforcement"

---

## PHASE 2 — ECG Waveform Improvements + New Rhythms

### 2A. Expand ECGRhythm enum
Update lib/models/ecg_rhythm_model.dart to add:

  torsades,           // Torsades de Pointes — shockable
  aivr,               // Accelerated Idioventricular Rhythm — non-shockable, post-ROSC
  sinusBradycardia,   // Sinus Bradycardia < 50bpm
  sinusTachycardia,   // Sinus Tachycardia 100–150bpm
  svt,                // SVT / AVNRT — narrow complex 180–220bpm
  afib,               // Atrial Fibrillation — irregularly irregular
  aflutter,           // Atrial Flutter — sawtooth 300bpm, 2:1 or 4:1
  vtachPulsed,        // VT with pulse — wide complex 150–200bpm
  avBlock1,           // 1st degree AV block — prolonged PR > 200ms
  avBlock2Mobitz2,    // Mobitz II — fixed PR, sudden dropped QRS
  avBlock3,           // Complete Heart Block — AV dissociation
  junctional,         // Junctional rhythm 40–60bpm

Update extension with:
  - displayName for each
  - isShockable: torsades = true (shock if unstable), pvt = true, vf = true
  - heartRate for each:
    sinusBradycardia: 40, svt: 200, afib: 110 (avg), aflutter: 75 (4:1), vtachPulsed: 170
    avBlock3: 35, junctional: 50, aivr: 55, torsades: 200, sinusTachycardia: 120
  - hasPulse getter: true for sinusBradycardia/sinusTachycardia/svt/afib/aflutter/vtachPulsed/avBlock1/avBlock2Mobitz2/avBlock3/junctional/normalSinus/aivr

### 2B. Improve ECG waveform generator
Update lib/widgets/ecg_monitor.dart — completely rewrite the waveform generation methods:

_generateY(index) switch routes to:
  ECGRhythm.vf => _vfPattern(index)           — improved
  ECGRhythm.pvt => _pvtPattern(index)          — improved  
  ECGRhythm.torsades => _torsadesPattern(index)
  ECGRhythm.pea => _peaPattern(index)
  ECGRhythm.asystole => _asystolePattern()
  ECGRhythm.aivr => _aivrPattern(index)
  ECGRhythm.normalSinus => _sinusPattern(index, bpm: 75)
  ECGRhythm.sinusBradycardia => _sinusPattern(index, bpm: 40)
  ECGRhythm.sinusTachycardia => _sinusPattern(index, bpm: 120)
  ECGRhythm.svt => _svtPattern(index)
  ECGRhythm.afib => _afibPattern(index)
  ECGRhythm.aflutter => _aflutterPattern(index)
  ECGRhythm.vtachPulsed => _vtachPattern(index)
  ECGRhythm.avBlock1 => _avBlock1Pattern(index)
  ECGRhythm.avBlock2Mobitz2 => _avBlock2Mobitz2Pattern(index)
  ECGRhythm.avBlock3 => _avBlock3Pattern(index)
  ECGRhythm.junctional => _junctionalPattern(index)

Implement each waveform:

_sinusPattern(index, {required int bpm}):
  - Cycle length = (60/bpm * sampleRate) samples, where sampleRate = 50 samples/sec
  - P-wave: small positive deflection at start of cycle (0.15 amplitude, narrow)
  - PR segment: flat (isoelectric) for 0.16s
  - QRS: Q small negative, R tall positive (1.5 amplitude), S small negative — total 0.08s
  - ST segment: flat 0.12s
  - T-wave: asymmetric positive (0.35 amplitude, slow up fast down) 0.16s
  - Return to baseline rest of cycle

_vfPattern(index):
  - Chaotic: random amplitude ±1.0 but with slight periodicity every 4–6 samples
  - Amplitude varies over time: add a slow envelope oscillation (sin(index/80)) * 0.3 to base amplitude
  - This gives the "coarse vs fine" variation feel

_pvtPattern(index):
  - Cycle ~14 samples, sinusoidal but with beat-to-beat variation
  - Each beat: amplitude = 1.2 + sin(index * 0.3) * 0.3 (varies ±25%)
  - Slight "twist" in axis: phase shift of sin varies slowly

_torsadesPattern(index):
  - Core rhythm: fast sinusoidal at ~200bpm cycle
  - Amplitude envelope: sin(index / 60) — waxes and wanes over ~12 beats
  - When amplitude is near zero: small biphasic complexes
  - When amplitude is high: tall sinusoidal pattern
  - This creates the characteristic "twisting" appearance

_svtPattern(index):
  - Like sinusPattern but at 200bpm
  - NO visible P-wave (P buried in T or retrograde)
  - Narrow QRS (same as sinus but no P)
  - Very regular RR

_afibPattern(index):
  - Irregular RR intervals: use a seeded pattern of interval variation ±30%
    e.g., cycle array: [38, 45, 32, 51, 39, 44, 36, 48, 41, 37] samples — repeat
  - Absent P-waves, replaced by fine fibrillatory baseline (random noise 0.05 amplitude)
  - QRS morphology: same as sinus (NSR QRS shape)

_aflutterPattern(index):
  - Regular sawtooth waves at 300bpm (10 samples/cycle)
  - Every 4th sawtooth: overlaid with a QRS complex (4:1 block = 75bpm ventricular rate)
  - Sawtooth: linear ramp from -0.3 to +0.3 then sharp drop back (not sinusoidal)

_vtachPattern(index):
  - Like pvt but slightly slower (170bpm) and MORE regular (less amplitude variation)
  - Wide QRS: 0.12s duration (6 samples at 50/sec)
  - Monomorphic: consistent shape beat to beat

_avBlock3Pattern(index):
  - P-waves: fire at 70bpm (43 samples/cycle) — small positive deflections
  - QRS: fire at 35bpm (86 samples/cycle) — COMPLETELY INDEPENDENT of P
  - P-waves and QRS march out at their own rates, occasionally overlapping randomly
  - This is the key diagnostic feature of 3rd degree block

_avBlock2Mobitz2Pattern(index):
  - Regular P-waves at 70bpm
  - QRS fires after every 2nd P-wave (2:1 block) with CONSISTENT PR interval
  - Dropped beats: P fires with NO QRS following

_junctionalPattern(index):
  - Sinus at 50bpm but NO visible P-wave (or inverted P just before QRS)
  - Narrow QRS, regular

_aivrPattern(index):
  - Wide QRS complexes at 60–70bpm (similar to vtach but slower)
  - Regular, monomorphic

_peaPattern(index):
  - Very small sinus-like complexes (amplitude 0.3) at 60bpm
  - Represents organized electrical without mechanical effect

### 2C. Torsades indicator
For torsades rhythm, add a text overlay in ECGMonitor: "TORSADES" label below the rhythm name, in yellow.

Commit: "feat: Phase 2 — expanded ECG rhythms (12 new) with clinically accurate waveforms"

---

## PHASE 3 — New Scenarios + Algorithm Screens

### 3A. Add new scenarios to scenario_model.dart

Add these scenarios to Scenario.all:

torsadesArrest:
  id: 'torsades_arrest', title: 'Torsades de Pointes'
  description: 'Patient with known long QT presents in cardiac arrest with torsades de pointes'
  initialRhythm: ECGRhythm.torsades
  difficulty: advanced
  objectives: 'Recognize torsades, deliver unsynchronized defibrillation, administer magnesium'
  keyActions: [shock, magnesium sulfate 2g, correct QT-prolonging meds, consider potassium]

symptomaticBradyAvBlock3:
  id: 'avblock3_bradycardia', title: 'Complete Heart Block'
  description: 'Patient with syncope, HR 35, complete AV dissociation on ECG'
  initialRhythm: ECGRhythm.avBlock3
  difficulty: intermediate
  objectives: 'Recognize 3rd degree block, initiate transcutaneous pacing, prepare for transvenous pacing'
  keyActions: [atropine (likely ineffective), transcutaneous pacing, dopamine/epi infusion]

unstableSVT:
  id: 'unstable_svt', title: 'Unstable SVT'
  description: 'Patient with HR 210, BP 70/40, altered mental status'
  initialRhythm: ECGRhythm.svt
  difficulty: intermediate
  objectives: 'Recognize unstable SVT, perform synchronized cardioversion'
  keyActions: [IV access, sedation if time allows, synchronized cardioversion 50-100J, do NOT give adenosine if unstable]

stableSVT:
  id: 'stable_svt', title: 'Stable SVT'
  description: 'Patient with palpitations, HR 190, BP 120/80, narrow complex'
  initialRhythm: ECGRhythm.svt
  difficulty: beginner
  objectives: 'Recognize SVT, vagal maneuvers, adenosine'
  keyActions: [vagal maneuvers, adenosine 6mg, adenosine 12mg if fails, rate control if refractory]

### 3B. Scenario categories for HomeScreen
Update Scenario model to add a `category` field:
  enum ScenarioCategory { shockableArrest, nonShockableArrest, tachycardia, bradycardia }

Group scenarios by category on home screen.

### 3C. Tachycardia-specific simulation modifications
When a scenario has a pulsed tachycardia rhythm (hasPulse == true):
- PatientState should initialize with pulse, BP, consciousness (not cardiacArrest state)
- CPR controls should be hidden (patient has pulse)
- Show "Stable" vs "Unstable" toggle (instability defined by: BP < 90, altered mental status, chest pain)
- Add "Synchronized Cardioversion" to defibrillator panel:
  - "SYNC MODE" toggle button — prevents unsynchronized shock
  - If user tries to shock without SYNC mode in a pulsed rhythm: warning "Unsynchronized shock on organized rhythm with pulse — are you sure?"

### 3D. Bradycardia-specific simulation modifications
When scenario rhythm is a bradycardia:
- Show "Symptomatic?" assessment button first
- Add "Transcutaneous Pacing" to defibrillator panel:
  - Rate selector (60–100 bpm)
  - Current selector (mA: 0–200)
  - "Capture" achieved if: rate > intrinsic rate AND current > 60mA (randomized threshold 60–100mA)
  - Show "Pacing Spikes" on ECG when pacing active (add vertical spike before each QRS)
- Atropine panel replaces medication panel for bradycardia scenarios:
  - Atropine 0.5mg button, tracks cumulative dose (max 3mg)
  - Note: "Atropine not recommended for Mobitz II or 3rd degree block"

Commit: "feat: Phase 3 — new scenarios (torsades, 3rd degree AVB, stable/unstable SVT), tachycardia/bradycardia algorithm paths"

---

## PHASE 4 — Event Log & Debrief

### 4A. EventLog model
Create lib/models/event_log_model.dart:

  enum EventCategory { cpr, medication, shock, airway, assessment, rosc, error, info }

  class SimulationEvent {
    final int timeSeconds;
    final String description;
    final EventCategory category;
    final bool isError;
    final bool isSuccess;
  }

### 4B. Integrate EventLog into SimulationService
- Add List<SimulationEvent> _eventLog to SimulationService
- Add getter: List<SimulationEvent> get eventLog
- Log events throughout:
  - startScenario: "Scenario started: [title] — Initial rhythm: [rhythm]"
  - analyzeRhythm: "Rhythm analyzed: [rhythm]" (category: assessment)
  - deliverShock: "⚡ Shock #N delivered ([J]J) — [rhythm persists/changed to X/ROSC]" 
  - administerMedication: "[Med] [dose] administered" — if wasEarly: isError=true, description includes "(too early: Xm Xs since last dose)"
  - performCompression (every 30th): "30 compressions" (batched, not per-compression)
  - resetCprCycle: "2-minute CPR cycle complete"
  - toggleReversibleCause: "H&T checked: [cause name]"
  - setAirwayDevice: "Airway: [device] placed"
  - _achieveROSC: "🎉 ROSC achieved at [time]" (category: rosc, isSuccess: true)
  - endScenario: "Scenario ended"

### 4C. Event Log Widget
Create lib/widgets/event_log_panel.dart:
  - Scrolling list of SimulationEvents
  - Color per category: CPR=blue, Medication=purple, Shock=orange, ROSC=green, Error=red, Assessment=teal
  - Time formatted as MM:SS prefix
  - Auto-scrolls to bottom as new events arrive
  - Collapsible (toggle button in app bar)

### 4D. Show event log in simulation screen
- Add EventLogPanel to the right side of SimulationScreen in wide layout
- In narrow layout: show as a collapsible bottom drawer

### 4E. Show event log on results screen
- Update lib/screens/results_screen.dart to include the full event timeline
- Show as a chronological list below the performance score
- Highlight errors in red with specific corrective feedback:
  - "Epinephrine given at 1:58 — should be ≥ 3:00 after previous dose. Given 1:02 too early."
  - "Amiodarone given before 3rd shock — should be administered after shock #3"
  - "CPR paused for 38 seconds after shock — minimize interruptions"

Commit: "feat: Phase 4 — real-time event log with timestamped debrief timeline on results screen"

---

## PHASE 5 — Post-ROSC Care & Reference Panel

### 5A. Post-ROSC care phase
After _achieveROSC() is called, instead of ending simulation:
- Transition SimulationService to a new state: `SimulationPhase.postROSC`
- Show PostROSCScreen (or update SimulationScreen with new panel set)

Create lib/screens/post_rosc_screen.dart:
  - Header: "ROSC Achieved — Post-Cardiac Arrest Care"
  - Patient vitals updating dynamically (BP starts low ~80/50, O2 sat starts at 88%)
  - Decision checklist:
    □ Optimize oxygen (target SpO2 94-99%) — slider control → O2 sat improves if set correctly
    □ Target SBP > 90 mmHg — vasopressor button (norepinephrine) → BP improves
    □ Obtain 12-lead ECG — button → shows "STEMI pattern detected / No STEMI"
    □ If STEMI: activate Cath Lab — button (correct action if STEMI present)
    □ Temperature management — target 36°C normothermia (button)
    □ Avoid hyperoxia — if O2 set to 100%: warning "Hyperoxia associated with worse outcomes"
  - Each correct action adds to score
  - "Transfer to ICU" button ends the simulation and goes to results

### 5B. Reference Panel
Create lib/widgets/reference_panel.dart:
  - A collapsible side drawer or floating panel
  - Tabs:
    1. "Algorithm" — visual flowchart for current scenario type (VF/pVT, PEA/asystole, tachy, brady)
       Use a simple tree of Container/Row widgets showing the algorithm steps
    2. "Drugs" — quick reference card:
       Epi: 1mg IV/IO q3-5min
       Amio: 300mg after 3rd shock, 150mg after 5th
       Lidocaine: 1-1.5mg/kg (alt to amio)
       Mag: 2g for torsades
       Atropine: 0.5mg q3-5min (brady, max 3mg)
    3. "H's & T's" — two-column list of all 10 reversible causes with brief descriptions
  - Toggle button in simulation screen AppBar: "📋 Reference"

### 5C. Progress Dashboard on HomeScreen
Create lib/services/stats_service.dart:
  - Reads/writes to localStorage (use dart:html for web) or shared_preferences
  - Tracks: List<SessionResult> { scenarioId, achievedROSC, timeToFirstShock, timeToFirstEpi, totalTimeSeconds, errorCount, completedAt }
  - Methods: saveResult(SessionResult), getAllResults(), getStatsForScenario(id), getOverallStats()

Create lib/screens/stats_screen.dart:
  - Total sessions, ROSC rate, avg time to first shock, avg time to first epi
  - Performance trend (last 10 sessions)
  - Weak areas summary
  - Add "Stats" button to HomeScreen

Commit: "feat: Phase 5 — post-ROSC care phase, in-sim reference panel, progress stats dashboard"

---

## PHASE 6 — UX & Polish

### 6A. Responsive layout
Update SimulationScreen:
  - LayoutBuilder to detect screen width
  - Wide (> 900px): Row layout — left column (ECG + vitals + CPR), right column (defibrillator + meds + event log)
  - Narrow (< 900px): Column layout (existing)
  - The ECG monitor should be taller on wide screens (200px vs 140px)

### 6B. ROSC animation
When ROSC is achieved:
  - Overlay a full-screen AnimatedContainer that pulses green briefly
  - Text "ROSC ACHIEVED" fades in large
  - Patient vitals animate to their new values over 3 seconds
  - After 2 seconds, show "Continue to Post-ROSC Care" button

### 6C. Dark mode
- Add ThemeMode toggle to SimulationService (or separate ThemeService)
- Dark theme: Colors.black background, Colors.green[400] accents, white text
- Light theme: existing
- Store in localStorage
- Toggle button in AppBar

### 6D. Home screen redesign
Update lib/screens/home_screen.dart:
  - Group scenarios by category (Arrest / Tachycardia / Bradycardia)
  - Category headers with icons
  - Each scenario card shows: difficulty badge, estimated time, completion status (✓ if in stats)
  - "Stats" button in AppBar
  - "Reference" quick-access button

### 6E. Results screen improvements
- Already updated in Phase 4 (event log)
- Add: "Retry" button (restart same scenario)
- Add: "Export" button (copies a text summary to clipboard for documentation)
- Show benchmark comparisons: "Your time to first shock: 0:22 (Target: < 0:30) ✓"

Commit: "feat: Phase 6 — responsive layout, ROSC animation, dark mode, home screen redesign, results improvements"

---

## GENERAL RULES
- Use Provider (already in pubspec) for state management — do NOT switch to Riverpod
- Use fl_chart (already in pubspec) for any charts
- Keep everything working as a Flutter web app (no native plugins)
- Run flutter analyze after each phase — fix all errors
- Run flutter build web after Phase 1 and Phase 6 to confirm web build succeeds
- All waveform math uses dart:math (sin, cos, Random) — no external packages needed
- Do NOT use firebase or any backend — this is a fully local/stateless training tool
- Maintain keyboard shortcuts (C=compression, B=breath, Space=pause)
- Keep the existing blue medical theme as the default light theme

When completely done with all phases, run:
/Users/macmini/Dev/notify-complete.sh "ACLS Simulator: All features implemented — medication timing, 12 new rhythms, event log, post-ROSC care, all phases complete"
