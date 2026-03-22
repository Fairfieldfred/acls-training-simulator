import 'package:flutter/material.dart';

/// Collapsible reference panel with algorithm, drugs, and
/// H's & T's quick reference tabs.
class ReferencePanel extends StatelessWidget {
  const ReferencePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TabBar(
              labelColor: Colors.blue,
              tabs: [
                Tab(text: 'Algorithm'),
                Tab(text: 'Drugs'),
                Tab(text: "H's & T's"),
              ],
            ),
            SizedBox(
              height: 280,
              child: TabBarView(
                children: [
                  _AlgorithmTab(),
                  _DrugsTab(),
                  _HsTsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlgorithmTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AlgoStep(
            title: 'VF / pVT (Shockable)',
            steps: [
              'CPR -> Rhythm Check',
              'Shock (200J biphasic)',
              'CPR 2 min -> Rhythm Check',
              'Shock -> Epi q3-5min',
              'Shock -> Amiodarone 300mg',
              'Repeat: CPR -> Shock -> Meds',
            ],
            color: Colors.red,
          ),
          SizedBox(height: 12),
          _AlgoStep(
            title: 'PEA / Asystole (Non-Shockable)',
            steps: [
              'CPR -> Rhythm Check',
              'Epi ASAP, then q3-5min',
              'CPR 2 min -> Rhythm Check',
              "Search H's and T's",
              'If shockable -> go to VF/pVT',
            ],
            color: Colors.blue,
          ),
          SizedBox(height: 12),
          _AlgoStep(
            title: 'Tachycardia',
            steps: [
              'Unstable? -> Cardioversion',
              'Stable narrow: Vagal -> Adenosine',
              'Stable wide: Amiodarone',
            ],
            color: Colors.orange,
          ),
          SizedBox(height: 12),
          _AlgoStep(
            title: 'Bradycardia',
            steps: [
              'Symptomatic? -> Atropine 0.5mg',
              'If no response -> TCP',
              'Consider dopamine/epi drip',
            ],
            color: Colors.purple,
          ),
        ],
      ),
    );
  }
}

class _AlgoStep extends StatelessWidget {
  final String title;
  final List<String> steps;
  final Color color;

  const _AlgoStep({
    required this.title,
    required this.steps,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          ...steps.asMap().entries.map((e) {
            return Padding(
              padding:
                  const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.key + 1}. ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DrugsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          _DrugCard(
            name: 'Epinephrine',
            dose: '1 mg IV/IO',
            interval: 'Every 3-5 min',
            color: Colors.red,
          ),
          _DrugCard(
            name: 'Amiodarone',
            dose: '300 mg IV (1st), 150 mg (2nd)',
            interval: '1st after 3rd shock',
            color: Colors.purple,
          ),
          _DrugCard(
            name: 'Lidocaine',
            dose: '1-1.5 mg/kg IV',
            interval: 'Alt to amiodarone',
            color: Colors.orange,
          ),
          _DrugCard(
            name: 'Magnesium',
            dose: '2 g IV',
            interval: 'Torsades only',
            color: Colors.teal,
          ),
          _DrugCard(
            name: 'Atropine',
            dose: '0.5 mg IV',
            interval: 'q3-5min, max 3mg',
            color: Colors.blue,
          ),
          _DrugCard(
            name: 'Adenosine',
            dose: '6 mg, then 12 mg',
            interval: 'Rapid IV push (SVT)',
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _DrugCard extends StatelessWidget {
  final String name;
  final String dose;
  final String interval;
  final Color color;

  const _DrugCard({
    required this.name,
    required this.dose,
    required this.interval,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: BorderSide(
            color: color,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              dose,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              interval,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HsTsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "H's",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 6),
                const _HtItem('Hypovolemia', 'IV fluids'),
                const _HtItem('Hypoxia', 'Ventilation'),
                const _HtItem(
                  'H+ (Acidosis)',
                  'Bicarb',
                ),
                const _HtItem(
                  'Hyper/Hypokalemia',
                  'Calcium/K+',
                ),
                const _HtItem(
                  'Hypothermia',
                  'Rewarm',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "T's",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.red[800],
                  ),
                ),
                const SizedBox(height: 6),
                const _HtItem(
                  'Tension Pneumo',
                  'Needle decomp',
                ),
                const _HtItem(
                  'Tamponade',
                  'Pericardiocentesis',
                ),
                const _HtItem('Toxins', 'Antidotes'),
                const _HtItem(
                  'Thrombosis (PE)',
                  'Lytics',
                ),
                const _HtItem(
                  'Thrombosis (MI)',
                  'PCI',
                ),
                const _HtItem('Trauma', 'Surgery'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HtItem extends StatelessWidget {
  final String cause;
  final String treatment;

  const _HtItem(this.cause, this.treatment);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(
                    text: cause,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: ' — $treatment'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
