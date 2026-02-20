class ReversibleCause {
  final String id;
  final String name;
  final String category; // 'H' or 'T'
  final String description;
  final List<String> signs;
  final List<String> treatments;

  const ReversibleCause({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.signs,
    required this.treatments,
  });

  // The H's
  static const hypovolemia = ReversibleCause(
    id: 'hypovolemia',
    name: 'Hypovolemia',
    category: 'H',
    description: 'Low blood volume',
    signs: ['History of bleeding', 'Trauma', 'Dehydration', 'Flat neck veins'],
    treatments: ['IV fluids', 'Blood products', 'Control bleeding'],
  );

  static const hypoxia = ReversibleCause(
    id: 'hypoxia',
    name: 'Hypoxia',
    category: 'H',
    description: 'Low oxygen levels',
    signs: ['Cyanosis', 'Low SpO2', 'Respiratory distress'],
    treatments: ['High-flow O2', 'Ventilation', 'Airway management'],
  );

  static const hydrogen = ReversibleCause(
    id: 'hydrogen',
    name: 'Hydrogen Ion (Acidosis)',
    category: 'H',
    description: 'Metabolic acidosis',
    signs: ['Hyperventilation', 'Diabetic history', 'Renal failure'],
    treatments: ['Sodium bicarbonate', 'Treat underlying cause'],
  );

  static const hyperkalemia = ReversibleCause(
    id: 'hyperkalemia',
    name: 'Hyperkalemia',
    category: 'H',
    description: 'High potassium',
    signs: ['Renal failure', 'Peaked T waves', 'Wide QRS'],
    treatments: ['Calcium chloride', 'Insulin + dextrose', 'Bicarbonate', 'Dialysis'],
  );

  static const hypokalemia = ReversibleCause(
    id: 'hypokalemia',
    name: 'Hypokalemia',
    category: 'H',
    description: 'Low potassium',
    signs: ['Diuretic use', 'Flat T waves', 'U waves'],
    treatments: ['Potassium replacement', 'Magnesium replacement'],
  );

  static const hypothermia = ReversibleCause(
    id: 'hypothermia',
    name: 'Hypothermia',
    category: 'H',
    description: 'Low body temperature',
    signs: ['Cold exposure', 'Core temp <35°C', 'Osborn waves'],
    treatments: ['Active rewarming', 'Warm IV fluids', 'ECMO if available'],
  );

  // The T's
  static const tension = ReversibleCause(
    id: 'tension',
    name: 'Tension Pneumothorax',
    category: 'T',
    description: 'Air trapped in pleural space',
    signs: ['Unilateral breath sounds', 'Distended neck veins', 'Tracheal deviation'],
    treatments: ['Needle decompression', 'Chest tube'],
  );

  static const tamponade = ReversibleCause(
    id: 'tamponade',
    name: 'Cardiac Tamponade',
    category: 'T',
    description: 'Fluid around heart',
    signs: ['Distended neck veins', 'Muffled heart sounds', 'Hypotension'],
    treatments: ['Pericardiocentesis', 'Surgical drainage'],
  );

  static const toxins = ReversibleCause(
    id: 'toxins',
    name: 'Toxins',
    category: 'T',
    description: 'Drug/chemical poisoning',
    signs: ['History of ingestion', 'Specific drug effects'],
    treatments: ['Specific antidotes', 'Naloxone', 'Lipid emulsion'],
  );

  static const thrombosis = ReversibleCause(
    id: 'thrombosis_pulmonary',
    name: 'Thrombosis - Pulmonary',
    category: 'T',
    description: 'Pulmonary embolism',
    signs: ['Sudden dyspnea', 'Chest pain', 'DVT history'],
    treatments: ['Thrombolytics', 'Anticoagulation', 'Surgical embolectomy'],
  );

  static const thrombosisCoronary = ReversibleCause(
    id: 'thrombosis_coronary',
    name: 'Thrombosis - Coronary',
    category: 'T',
    description: 'Acute MI',
    signs: ['Chest pain', 'ST elevation', 'Cardiac markers'],
    treatments: ['PCI', 'Thrombolytics', 'Antiplatelet therapy'],
  );

  static const trauma = ReversibleCause(
    id: 'trauma',
    name: 'Trauma',
    category: 'T',
    description: 'Physical injury',
    signs: ['History of trauma', 'Visible injuries', 'Bleeding'],
    treatments: ['Control bleeding', 'Surgery', 'Blood products'],
  );

  static List<ReversibleCause> get allCauses => [
        // H's
        hypovolemia,
        hypoxia,
        hydrogen,
        hyperkalemia,
        hypokalemia,
        hypothermia,
        // T's
        tension,
        tamponade,
        toxins,
        thrombosis,
        thrombosisCoronary,
        trauma,
      ];

  static List<ReversibleCause> get hCauses =>
      allCauses.where((c) => c.category == 'H').toList();

  static List<ReversibleCause> get tCauses =>
      allCauses.where((c) => c.category == 'T').toList();
}
