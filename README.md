# ACLS Training Simulator

A comprehensive Advanced Cardiac Life Support (ACLS) training simulator built with Flutter, based on the 2025 AHA Guidelines.

## Features

### Phase 1 - Core Simulation
✅ Real-time ECG monitor with animated waveforms (VF, pVT, PEA, Asystole, Normal Sinus)
✅ Code timer and CPR cycle timer with 2-minute alerts
✅ Interactive CPR controls (compressions and ventilations) with ratio tracking
✅ Defibrillator panel (analyze, charge, shock) with energy selection (120J, 150J, 200J)
✅ Medication administration with comprehensive ACLS drug library
✅ Patient avatar with vital signs and status indicators

### Phase 2 - Scenarios and Reversible Causes
✅ Multiple training scenarios:
   - VF Cardiac Arrest (Beginner)
   - Asystole (Beginner)
   - PEA Arrest (Intermediate)
   - Refractory VF (Advanced)
✅ Interactive H's and T's checklist (12 reversible causes)
✅ Home screen with scenario selection
✅ Scenario objectives and key actions

### Phase 3 - Performance Tracking
✅ Comprehensive performance scoring (100-point scale)
✅ Performance criteria tracking:
   - Time to first shock
   - CPR quality (30:2 ratio)
   - Compression count
   - Epinephrine timing
   - Antiarrhythmic administration
   - Reversible causes consideration
   - Airway management
   - ROSC achievement
✅ Detailed results screen with:
   - Overall grade (A-F)
   - Key metrics summary
   - Detailed breakdown by criteria
   - Medications administered list
   - Actionable feedback
✅ Advanced airway management:
   - BVM (Bag-Valve-Mask)
   - King LT (Laryngeal Tube)
   - i-gel (Supraglottic Airway)
   - ETT (Endotracheal Tube)

## Installation

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Dart 3.0.0 or higher

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/Fairfieldfred/acls-training-simulator.git
   cd acls-training-simulator
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/                            # Data models
│   ├── ecg_rhythm_model.dart         # ECG rhythm types
│   ├── medication_model.dart         # ACLS medications
│   ├── patient_model.dart            # Patient state
│   ├── performance_model.dart        # Performance scoring
│   ├── reversible_causes_model.dart  # H's and T's
│   └── scenario_model.dart           # Training scenarios
├── services/                          # Business logic
│   └── simulation_service.dart       # State management with Provider
├── widgets/                           # Reusable UI components
│   ├── airway_panel.dart             # Airway device selection
│   ├── cpr_controls.dart             # CPR compression/ventilation buttons
│   ├── defibrillator_panel.dart      # Defibrillator controls
│   ├── ecg_monitor.dart              # Animated ECG waveforms
│   ├── medication_panel.dart         # Medication administration
│   ├── patient_avatar.dart           # Patient visualization
│   ├── reversible_causes_panel.dart  # H's and T's checklist
│   └── timer_display.dart            # Code and CPR cycle timers
└── screens/                           # App screens
    ├── home_screen.dart              # Scenario selection
    ├── results_screen.dart           # Performance report
    └── simulation_screen.dart        # Main simulation interface
```

## Dependencies

- **provider** (^6.0.5): State management
- **fl_chart** (^0.66.0): ECG waveform visualization

## Usage

### Starting a Scenario
1. Launch the app
2. Select a scenario from the home screen
3. Review objectives and key actions
4. Tap the scenario card to begin

### During Simulation
1. Monitor the ECG rhythm and patient vitals
2. Perform CPR using compression and ventilation buttons
3. Analyze rhythm and deliver shocks as appropriate
4. Administer medications according to ACLS protocols
5. Check and manage reversible causes (H's and T's)
6. Place advanced airway when appropriate
7. Watch for 2-minute cycle alerts to check rhythm

### Ending Simulation
1. Tap the stop button in the app bar
2. Confirm to end and view performance report
3. Review your score, metrics, and feedback
4. Choose to try again or return to home

## Performance Scoring

Scores are based on:
- **Early Defibrillation** (20 pts): Shock within 60 seconds for shockable rhythms
- **CPR Quality** (15 pts): Maintaining 30:2 compression-ventilation ratio
- **Adequate Compressions** (10 pts): >100 compressions per minute
- **Epinephrine Timing** (15 pts): First dose within 3-5 minutes
- **Antiarrhythmic Given** (10 pts): Amiodarone or Lidocaine for VF/pVT
- **H's and T's Considered** (15 pts): Checking at least 6 reversible causes
- **Airway Management** (10 pts): Advanced airway placement
- **ROSC Achieved** (15 pts): Return of spontaneous circulation

Grades:
- **A**: 90-100% - Excellent!
- **B**: 80-89% - Good job
- **C**: 70-79% - Satisfactory
- **D**: 60-69% - Needs improvement
- **F**: <60% - Unsatisfactory

## Future Enhancements (Phase 4)

Planned features include:
- Audio feedback system (metronome, voice prompts)
- Pediatric ACLS scenarios
- Team-based training mode
- Advanced analytics dashboard
- Certification mode with PDF certificates
- Cloud integration (user accounts, leaderboards)
- Bluetooth manikin support
- Video replay system

## License

This is an educational training tool for ACLS protocols based on AHA Guidelines.

## Author

Built with Claude Code
