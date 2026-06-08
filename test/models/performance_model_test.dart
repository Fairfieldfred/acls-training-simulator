import 'package:flutter_test/flutter_test.dart';
import 'package:acls_simulator/models/performance_model.dart';
import 'package:acls_simulator/models/training_config.dart';

void main() {
  group('PerformanceScore', () {
    group('grade thresholds', () {
      test('percentage >= 90 yields grade A', () {
        final score = PerformanceScore(
          criteria: [
            const PerformanceCriteria(
              id: 'test',
              name: 'Test',
              description: 'Test',
              maxPoints: 100,
              achieved: true,
            ),
          ],
          metrics: const PerformanceMetrics(),
        );
        expect(score.percentage, 100.0);
        expect(score.grade, 'A');
        expect(score.feedback, contains('Excellent'));
      });

      test('percentage >= 80 yields grade B', () {
        final score = PerformanceScore(
          criteria: [
            const PerformanceCriteria(
              id: 'a',
              name: 'A',
              description: '',
              maxPoints: 80,
              achieved: true,
            ),
            const PerformanceCriteria(
              id: 'b',
              name: 'B',
              description: '',
              maxPoints: 20,
              achieved: false,
            ),
          ],
          metrics: const PerformanceMetrics(),
        );
        expect(score.percentage, 80.0);
        expect(score.grade, 'B');
        expect(score.feedback, contains('Good'));
      });

      test('percentage >= 70 yields grade C', () {
        final score = PerformanceScore(
          criteria: [
            const PerformanceCriteria(
              id: 'a',
              name: 'A',
              description: '',
              maxPoints: 70,
              achieved: true,
            ),
            const PerformanceCriteria(
              id: 'b',
              name: 'B',
              description: '',
              maxPoints: 30,
              achieved: false,
            ),
          ],
          metrics: const PerformanceMetrics(),
        );
        expect(score.percentage, 70.0);
        expect(score.grade, 'C');
        expect(score.feedback, contains('Satisfactory'));
      });

      test('percentage >= 60 yields grade D', () {
        final score = PerformanceScore(
          criteria: [
            const PerformanceCriteria(
              id: 'a',
              name: 'A',
              description: '',
              maxPoints: 60,
              achieved: true,
            ),
            const PerformanceCriteria(
              id: 'b',
              name: 'B',
              description: '',
              maxPoints: 40,
              achieved: false,
            ),
          ],
          metrics: const PerformanceMetrics(),
        );
        expect(score.percentage, 60.0);
        expect(score.grade, 'D');
        expect(score.feedback, contains('Needs improvement'));
      });

      test('percentage < 60 yields grade F', () {
        final score = PerformanceScore(
          criteria: [
            const PerformanceCriteria(
              id: 'a',
              name: 'A',
              description: '',
              maxPoints: 50,
              achieved: true,
            ),
            const PerformanceCriteria(
              id: 'b',
              name: 'B',
              description: '',
              maxPoints: 50,
              achieved: false,
            ),
          ],
          metrics: const PerformanceMetrics(),
        );
        expect(score.percentage, 50.0);
        expect(score.grade, 'F');
        expect(score.feedback, contains('Unsatisfactory'));
      });

      test('maxPoints of 0 returns 0 percentage', () {
        const score = PerformanceScore(
          criteria: [],
          metrics: PerformanceMetrics(),
        );
        expect(score.percentage, 0);
      });
    });

    group('calculate - scenario-specific criteria', () {
      test('VF scenario includes time_to_shock criterion', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(),
          'vf_arrest',
        );
        final ids = score.criteria.map((c) => c.id).toList();
        expect(ids, contains('time_to_shock'));
      });

      test('refractory VF includes time_to_shock criterion', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(),
          'refractory_vf',
        );
        final ids = score.criteria.map((c) => c.id).toList();
        expect(ids, contains('time_to_shock'));
      });

      test('PEA scenario excludes time_to_shock', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(),
          'pea_arrest',
        );
        final ids = score.criteria.map((c) => c.id).toList();
        expect(ids, isNot(contains('time_to_shock')));
      });

      test('asystole scenario excludes time_to_shock', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(),
          'asystole_arrest',
        );
        final ids = score.criteria.map((c) => c.id).toList();
        expect(ids, isNot(contains('time_to_shock')));
      });

      test('VF scenario includes antiarrhythmic criterion', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(),
          'vf_arrest',
        );
        final ids = score.criteria.map((c) => c.id).toList();
        expect(ids, contains('antiarrhythmic'));
      });

      test('PEA scenario excludes antiarrhythmic criterion', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(),
          'pea_arrest',
        );
        final ids = score.criteria.map((c) => c.id).toList();
        expect(ids, isNot(contains('antiarrhythmic')));
      });
    });

    group('calculate - mode-specific behavior', () {
      test('protocol mode excludes cpr_quality', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(),
          'vf_arrest',
          trainingConfig: const TrainingConfig(
            focus: TrainingFocus.protocol,
          ),
        );
        final ids = score.criteria.map((c) => c.id).toList();
        expect(ids, isNot(contains('cpr_quality')));
      });

      test('protocol mode excludes compression_count', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(),
          'vf_arrest',
          trainingConfig: const TrainingConfig(
            focus: TrainingFocus.protocol,
          ),
        );
        final ids = score.criteria.map((c) => c.id).toList();
        expect(ids, isNot(contains('compression_count')));
      });

      test('timing mode includes cpr_quality for 30:2', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(),
          'vf_arrest',
          trainingConfig: const TrainingConfig(
            focus: TrainingFocus.timing,
            cprRatio: CprRatio.ratio30to2,
          ),
        );
        final ids = score.criteria.map((c) => c.id).toList();
        expect(ids, contains('cpr_quality'));
      });

      test('timing mode excludes cpr_quality for continuous', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(),
          'vf_arrest',
          trainingConfig: const TrainingConfig(
            focus: TrainingFocus.timing,
            cprRatio: CprRatio.continuous,
          ),
        );
        final ids = score.criteria.map((c) => c.id).toList();
        expect(ids, isNot(contains('cpr_quality')));
      });

      test('timing mode includes compression_count', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(),
          'vf_arrest',
          trainingConfig: const TrainingConfig(
            focus: TrainingFocus.timing,
          ),
        );
        final ids = score.criteria.map((c) => c.id).toList();
        expect(ids, contains('compression_count'));
      });
    });

    group('calculate - time_to_shock criterion', () {
      test('achieved when shock within 60 seconds', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(timeToFirstShock: 45),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'time_to_shock',
        );
        expect(criterion.achieved, isTrue);
      });

      test('achieved at exactly 60 seconds', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(timeToFirstShock: 60),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'time_to_shock',
        );
        expect(criterion.achieved, isTrue);
      });

      test('not achieved at 61 seconds', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(timeToFirstShock: 61),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'time_to_shock',
        );
        expect(criterion.achieved, isFalse);
      });

      test('not achieved when shock never delivered (0)', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(timeToFirstShock: 0),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'time_to_shock',
        );
        expect(criterion.achieved, isFalse);
      });
    });

    group('calculate - epi_timing criterion', () {
      test('achieved when within 300 seconds', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(
            timeToFirstEpinephrine: 180,
          ),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'epi_timing',
        );
        expect(criterion.achieved, isTrue);
      });

      test('achieved at exactly 300 seconds', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(
            timeToFirstEpinephrine: 300,
          ),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'epi_timing',
        );
        expect(criterion.achieved, isTrue);
      });

      test('not achieved at 301 seconds', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(
            timeToFirstEpinephrine: 301,
          ),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'epi_timing',
        );
        expect(criterion.achieved, isFalse);
      });

      test('not achieved when never given (0)', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(
            timeToFirstEpinephrine: 0,
          ),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'epi_timing',
        );
        expect(criterion.achieved, isFalse);
      });
    });

    group('calculate - antiarrhythmic criterion', () {
      test('achieved with amiodarone', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(
            medicationsGiven: ['Amiodarone 300 mg'],
          ),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'antiarrhythmic',
        );
        expect(criterion.achieved, isTrue);
      });

      test('achieved with lidocaine', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(
            medicationsGiven: ['Lidocaine 1-1.5 mg/kg'],
          ),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'antiarrhythmic',
        );
        expect(criterion.achieved, isTrue);
      });

      test('case insensitive match', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(
            medicationsGiven: ['AMIODARONE 300 mg'],
          ),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'antiarrhythmic',
        );
        expect(criterion.achieved, isTrue);
      });

      test('not achieved without antiarrhythmic', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(
            medicationsGiven: ['Epinephrine 1 mg'],
          ),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'antiarrhythmic',
        );
        expect(criterion.achieved, isFalse);
      });
    });

    group('calculate - reversible_causes criterion', () {
      test('achieved when 6 or more causes checked', () {
        final score = PerformanceScore.calculate(
          PerformanceMetrics(
            reversibleCausesChecked: {
              for (var i = 0; i < 6; i++) 'cause_$i': true,
            },
          ),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'reversible_causes',
        );
        expect(criterion.achieved, isTrue);
      });

      test('not achieved with 5 causes', () {
        final score = PerformanceScore.calculate(
          PerformanceMetrics(
            reversibleCausesChecked: {
              for (var i = 0; i < 5; i++) 'cause_$i': true,
            },
          ),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'reversible_causes',
        );
        expect(criterion.achieved, isFalse);
      });

      test('false values are not counted', () {
        final score = PerformanceScore.calculate(
          PerformanceMetrics(
            reversibleCausesChecked: {
              for (var i = 0; i < 6; i++) 'cause_$i': true,
              'cause_false': false,
            },
          ),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'reversible_causes',
        );
        expect(criterion.achieved, isTrue);
      });
    });

    group('calculate - airway criterion', () {
      test('not achieved with BVM', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(airwayUsed: 'BVM'),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'airway',
        );
        expect(criterion.achieved, isFalse);
      });

      test('achieved with advanced airway', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(airwayUsed: 'LMA'),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'airway',
        );
        expect(criterion.achieved, isTrue);
      });
    });

    group('calculate - rosc criterion', () {
      test('achieved when ROSC true', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(achievedROSC: true),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'rosc',
        );
        expect(criterion.achieved, isTrue);
      });

      test('not achieved when ROSC false', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(achievedROSC: false),
          'vf_arrest',
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'rosc',
        );
        expect(criterion.achieved, isFalse);
      });
    });

    group('calculate - cpr_quality criterion', () {
      test('achieved when ratio within 30:2 range', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(cprRatio: 15.0),
          'vf_arrest',
          trainingConfig: const TrainingConfig(
            focus: TrainingFocus.timing,
            cprRatio: CprRatio.ratio30to2,
          ),
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'cpr_quality',
        );
        expect(criterion.achieved, isTrue);
      });

      test('not achieved when ratio outside range', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(cprRatio: 20.0),
          'vf_arrest',
          trainingConfig: const TrainingConfig(
            focus: TrainingFocus.timing,
            cprRatio: CprRatio.ratio30to2,
          ),
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'cpr_quality',
        );
        expect(criterion.achieved, isFalse);
      });

      test('achieved at acceptable range boundary', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(cprRatio: 13.0),
          'vf_arrest',
          trainingConfig: const TrainingConfig(
            focus: TrainingFocus.timing,
            cprRatio: CprRatio.ratio30to2,
          ),
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'cpr_quality',
        );
        expect(criterion.achieved, isTrue);
      });
    });

    group('calculate - compression_count criterion', () {
      test('achieved when avg >= 100/min', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(
            totalCompressions: 200,
            totalTimeSeconds: 120,
          ),
          'vf_arrest',
          trainingConfig: const TrainingConfig(
            focus: TrainingFocus.timing,
          ),
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'compression_count',
        );
        expect(criterion.achieved, isTrue);
      });

      test('not achieved when avg < 100/min', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(
            totalCompressions: 100,
            totalTimeSeconds: 120,
          ),
          'vf_arrest',
          trainingConfig: const TrainingConfig(
            focus: TrainingFocus.timing,
          ),
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'compression_count',
        );
        expect(criterion.achieved, isFalse);
      });
    });

    group('calculate - point weighting', () {
      test('protocol mode awards 25pts for shock', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(timeToFirstShock: 30),
          'vf_arrest',
          trainingConfig: const TrainingConfig(
            focus: TrainingFocus.protocol,
          ),
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'time_to_shock',
        );
        expect(criterion.maxPoints, 25);
      });

      test('timing mode awards 20pts for shock', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(timeToFirstShock: 30),
          'vf_arrest',
          trainingConfig: const TrainingConfig(
            focus: TrainingFocus.timing,
          ),
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'time_to_shock',
        );
        expect(criterion.maxPoints, 20);
      });

      test('protocol mode awards 20pts for epi timing', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(),
          'vf_arrest',
          trainingConfig: const TrainingConfig(
            focus: TrainingFocus.protocol,
          ),
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'epi_timing',
        );
        expect(criterion.maxPoints, 20);
      });

      test('timing mode awards 15pts for epi timing', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(),
          'vf_arrest',
          trainingConfig: const TrainingConfig(
            focus: TrainingFocus.timing,
          ),
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'epi_timing',
        );
        expect(criterion.maxPoints, 15);
      });

      test('timing mode awards 20pts for cpr_quality', () {
        final score = PerformanceScore.calculate(
          const PerformanceMetrics(),
          'vf_arrest',
          trainingConfig: const TrainingConfig(
            focus: TrainingFocus.timing,
            cprRatio: CprRatio.ratio30to2,
          ),
        );
        final criterion = score.criteria.firstWhere(
          (c) => c.id == 'cpr_quality',
        );
        expect(criterion.maxPoints, 20);
      });
    });
  });

  group('PerformanceMetrics', () {
    test('defaults are all zero/empty/false', () {
      const m = PerformanceMetrics();
      expect(m.totalCompressions, 0);
      expect(m.totalVentilations, 0);
      expect(m.cprRatio, 0);
      expect(m.shocksDelivered, 0);
      expect(m.timeToFirstShock, 0);
      expect(m.medicationsGiven, isEmpty);
      expect(m.timeToFirstEpinephrine, 0);
      expect(m.achievedROSC, isFalse);
      expect(m.totalTimeSeconds, 0);
      expect(m.reversibleCausesChecked, isEmpty);
      expect(m.airwayUsed, 'BVM');
    });

    test('copyWith preserves unmodified fields', () {
      const original = PerformanceMetrics(
        totalCompressions: 100,
        shocksDelivered: 3,
      );
      final copied = original.copyWith(shocksDelivered: 5);
      expect(copied.totalCompressions, 100);
      expect(copied.shocksDelivered, 5);
    });
  });

  group('PerformanceCriteria', () {
    test('copyWith updates achieved status', () {
      const c = PerformanceCriteria(
        id: 'test',
        name: 'Test',
        description: 'Test',
        maxPoints: 10,
        achieved: false,
      );
      final updated = c.copyWith(achieved: true);
      expect(updated.achieved, isTrue);
      expect(updated.id, 'test');
      expect(updated.maxPoints, 10);
    });
  });
}
