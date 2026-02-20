import 'ecg_rhythm_model.dart';

enum ScenarioDifficulty {
  beginner,
  intermediate,
  advanced,
}

class Scenario {
  final String id;
  final String title;
  final String description;
  final ECGRhythm initialRhythm;
  final ScenarioDifficulty difficulty;
  final String objectives;
  final List<String> keyActions;

  const Scenario({
    required this.id,
    required this.title,
    required this.description,
    required this.initialRhythm,
    required this.difficulty,
    required this.objectives,
    required this.keyActions,
  });

  static const vfArrest = Scenario(
    id: 'vf_arrest',
    title: 'VF Cardiac Arrest',
    description: 'Adult patient found unresponsive with ventricular fibrillation',
    initialRhythm: ECGRhythm.vf,
    difficulty: ScenarioDifficulty.beginner,
    objectives: 'Recognize VF, perform high-quality CPR, deliver early defibrillation',
    keyActions: [
      'Analyze rhythm',
      'Shock as soon as possible',
      'Resume CPR immediately after shock',
      'Give epinephrine every 3-5 minutes',
      'Consider amiodarone after 3rd shock',
    ],
  );

  static const asystoleArrest = Scenario(
    id: 'asystole_arrest',
    title: 'Asystole',
    description: 'Adult patient in cardiac arrest with asystole rhythm',
    initialRhythm: ECGRhythm.asystole,
    difficulty: ScenarioDifficulty.beginner,
    objectives: 'Recognize non-shockable rhythm, provide high-quality CPR, search for reversible causes',
    keyActions: [
      'Confirm asystole in two leads',
      'Do NOT shock',
      'High-quality CPR',
      'Epinephrine every 3-5 minutes',
      'Search H\'s and T\'s',
    ],
  );

  static const peaArrest = Scenario(
    id: 'pea_arrest',
    title: 'PEA Arrest',
    description: 'Cardiac arrest with organized electrical activity but no pulse',
    initialRhythm: ECGRhythm.pea,
    difficulty: ScenarioDifficulty.intermediate,
    objectives: 'Recognize PEA, provide CPR, aggressively search for reversible causes',
    keyActions: [
      'Confirm pulselessness',
      'Do NOT shock',
      'High-quality CPR',
      'Epinephrine every 3-5 minutes',
      'Identify and treat reversible causes (H\'s & T\'s)',
    ],
  );

  static const refractoryVF = Scenario(
    id: 'refractory_vf',
    title: 'Refractory VF',
    description: 'Persistent VF despite multiple shocks',
    initialRhythm: ECGRhythm.vf,
    difficulty: ScenarioDifficulty.advanced,
    objectives: 'Manage refractory VF with medications and reversible cause correction',
    keyActions: [
      'Continue CPR and defibrillation',
      'Amiodarone 300mg after 3rd shock',
      'Epinephrine every 3-5 minutes',
      'Consider double sequential defibrillation',
      'Aggressively treat H\'s and T\'s',
    ],
  );

  static List<Scenario> get all => [
        vfArrest,
        asystoleArrest,
        peaArrest,
        refractoryVF,
      ];
}
