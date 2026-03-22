import 'ecg_rhythm_model.dart';

enum ScenarioDifficulty {
  beginner,
  intermediate,
  advanced,
}

enum ScenarioCategory {
  shockableArrest,
  nonShockableArrest,
  tachycardia,
  bradycardia,
}

class Scenario {
  final String id;
  final String title;
  final String description;
  final ECGRhythm initialRhythm;
  final ScenarioDifficulty difficulty;
  final ScenarioCategory category;
  final String objectives;
  final List<String> keyActions;

  const Scenario({
    required this.id,
    required this.title,
    required this.description,
    required this.initialRhythm,
    required this.difficulty,
    required this.category,
    required this.objectives,
    required this.keyActions,
  });

  // ── Shockable arrest ───────────────────────────────────

  static const vfArrest = Scenario(
    id: 'vf_arrest',
    title: 'VF Cardiac Arrest',
    description: 'Adult patient found unresponsive '
        'with ventricular fibrillation',
    initialRhythm: ECGRhythm.vf,
    difficulty: ScenarioDifficulty.beginner,
    category: ScenarioCategory.shockableArrest,
    objectives: 'Recognize VF, perform high-quality '
        'CPR, deliver early defibrillation',
    keyActions: [
      'Analyze rhythm',
      'Shock as soon as possible',
      'Resume CPR immediately after shock',
      'Give epinephrine every 3-5 minutes',
      'Consider amiodarone after 3rd shock',
    ],
  );

  static const refractoryVF = Scenario(
    id: 'refractory_vf',
    title: 'Refractory VF',
    description: 'Persistent VF despite multiple shocks',
    initialRhythm: ECGRhythm.vf,
    difficulty: ScenarioDifficulty.advanced,
    category: ScenarioCategory.shockableArrest,
    objectives: 'Manage refractory VF with medications '
        'and reversible cause correction',
    keyActions: [
      'Continue CPR and defibrillation',
      'Amiodarone 300mg after 3rd shock',
      'Epinephrine every 3-5 minutes',
      'Consider double sequential defibrillation',
      "Aggressively treat H's and T's",
    ],
  );

  static const torsadesArrest = Scenario(
    id: 'torsades_arrest',
    title: 'Torsades de Pointes',
    description: 'Patient with known long QT presents '
        'in cardiac arrest with torsades de pointes',
    initialRhythm: ECGRhythm.torsades,
    difficulty: ScenarioDifficulty.advanced,
    category: ScenarioCategory.shockableArrest,
    objectives: 'Recognize torsades, deliver '
        'unsynchronized defibrillation, '
        'administer magnesium',
    keyActions: [
      'Defibrillation',
      'Magnesium sulfate 2g IV',
      'Correct QT-prolonging medications',
      'Consider potassium replacement',
    ],
  );

  // ── Non-shockable arrest ───────────────────────────────

  static const asystoleArrest = Scenario(
    id: 'asystole_arrest',
    title: 'Asystole',
    description: 'Adult patient in cardiac arrest '
        'with asystole rhythm',
    initialRhythm: ECGRhythm.asystole,
    difficulty: ScenarioDifficulty.beginner,
    category: ScenarioCategory.nonShockableArrest,
    objectives: 'Recognize non-shockable rhythm, '
        'provide high-quality CPR, '
        'search for reversible causes',
    keyActions: [
      'Confirm asystole in two leads',
      'Do NOT shock',
      'High-quality CPR',
      'Epinephrine every 3-5 minutes',
      "Search H's and T's",
    ],
  );

  static const peaArrest = Scenario(
    id: 'pea_arrest',
    title: 'PEA Arrest',
    description: 'Cardiac arrest with organized '
        'electrical activity but no pulse',
    initialRhythm: ECGRhythm.pea,
    difficulty: ScenarioDifficulty.intermediate,
    category: ScenarioCategory.nonShockableArrest,
    objectives: 'Recognize PEA, provide CPR, '
        'aggressively search for reversible causes',
    keyActions: [
      'Confirm pulselessness',
      'Do NOT shock',
      'High-quality CPR',
      'Epinephrine every 3-5 minutes',
      "Identify and treat reversible causes (H's & T's)",
    ],
  );

  // ── Tachycardia ────────────────────────────────────────

  static const unstableSVT = Scenario(
    id: 'unstable_svt',
    title: 'Unstable SVT',
    description: 'Patient with HR 210, BP 70/40, '
        'altered mental status',
    initialRhythm: ECGRhythm.svt,
    difficulty: ScenarioDifficulty.intermediate,
    category: ScenarioCategory.tachycardia,
    objectives: 'Recognize unstable SVT, perform '
        'synchronized cardioversion',
    keyActions: [
      'IV access',
      'Sedation if time allows',
      'Synchronized cardioversion 50-100J',
      'Do NOT give adenosine if unstable',
    ],
  );

  static const stableSVT = Scenario(
    id: 'stable_svt',
    title: 'Stable SVT',
    description: 'Patient with palpitations, HR 190, '
        'BP 120/80, narrow complex',
    initialRhythm: ECGRhythm.svt,
    difficulty: ScenarioDifficulty.beginner,
    category: ScenarioCategory.tachycardia,
    objectives: 'Recognize SVT, vagal maneuvers, '
        'adenosine',
    keyActions: [
      'Vagal maneuvers',
      'Adenosine 6mg rapid IV push',
      'Adenosine 12mg if fails',
      'Rate control if refractory',
    ],
  );

  // ── Bradycardia ────────────────────────────────────────

  static const avBlock3Bradycardia = Scenario(
    id: 'avblock3_bradycardia',
    title: 'Complete Heart Block',
    description: 'Patient with syncope, HR 35, '
        'complete AV dissociation on ECG',
    initialRhythm: ECGRhythm.avBlock3,
    difficulty: ScenarioDifficulty.intermediate,
    category: ScenarioCategory.bradycardia,
    objectives: 'Recognize 3rd degree block, initiate '
        'transcutaneous pacing',
    keyActions: [
      'Atropine (likely ineffective)',
      'Transcutaneous pacing',
      'Dopamine/epinephrine infusion',
    ],
  );

  static List<Scenario> get all => [
        vfArrest,
        refractoryVF,
        torsadesArrest,
        asystoleArrest,
        peaArrest,
        unstableSVT,
        stableSVT,
        avBlock3Bradycardia,
      ];

  /// Scenarios grouped by category.
  static Map<ScenarioCategory, List<Scenario>>
      get byCategory {
    final map = <ScenarioCategory, List<Scenario>>{};
    for (final s in all) {
      map.putIfAbsent(s.category, () => []).add(s);
    }
    return map;
  }
}
