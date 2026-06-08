import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acls_simulator/models/ecg_rhythm_model.dart';
import 'package:acls_simulator/models/medication_model.dart';
import 'package:acls_simulator/models/scenario_model.dart';
import 'package:acls_simulator/models/training_config.dart';
import 'package:acls_simulator/services/simulation_service.dart';

void main() {
  group('SimulationService', () {
    late SimulationService service;

    setUp(() {
      service = SimulationService();
    });

    tearDown(() {
      service.dispose();
    });

    group('startScenario', () {
      test('sets isRunning to true', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          expect(service.isRunning, isTrue);
        });
      });

      test('resets all counters to zero', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          expect(service.codeSeconds, 0);
          expect(service.cprCycleSeconds, 0);
          expect(service.compressions, 0);
          expect(service.ventilations, 0);
          expect(service.shockCount, 0);
        });
      });

      test(
          'sets patient to cardiac arrest with scenario '
          'rhythm', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          expect(
            service.patientState.rhythm,
            ECGRhythm.vf,
          );
          expect(service.patientState.hasROSC, isFalse);
        });
      });

      test('stores training config', () {
        fakeAsync((async) {
          const config = TrainingConfig(
            focus: TrainingFocus.protocol,
            cprRatio: CprRatio.ratio15to2,
          );
          service.startScenario(
            Scenario.vfArrest,
            config: config,
          );
          expect(service.trainingConfig.isProtocolMode, isTrue);
          expect(
            service.trainingConfig.cprRatio,
            CprRatio.ratio15to2,
          );
        });
      });

      test('stores current scenario', () {
        fakeAsync((async) {
          service.startScenario(Scenario.peaArrest);
          expect(service.currentScenario, Scenario.peaArrest);
        });
      });
    });

    group('timers', () {
      test('codeSeconds increments each second', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          async.elapse(const Duration(seconds: 5));
          expect(service.codeSeconds, 5);
        });
      });

      test('cprCycleSeconds increments each second', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          async.elapse(const Duration(seconds: 3));
          expect(service.cprCycleSeconds, 3);
        });
      });

      test('protocol mode starts auto-CPR timer', () {
        fakeAsync((async) {
          service.startScenario(
            Scenario.vfArrest,
            config: const TrainingConfig(
              focus: TrainingFocus.protocol,
            ),
          );
          async.elapse(const Duration(milliseconds: 545));
          expect(service.compressions, 1);
        });
      });

      test('timing mode does not start auto-CPR', () {
        fakeAsync((async) {
          service.startScenario(
            Scenario.vfArrest,
            config: const TrainingConfig(
              focus: TrainingFocus.timing,
            ),
          );
          async.elapse(const Duration(seconds: 2));
          expect(service.compressions, 0);
        });
      });
    });

    group('manual CPR', () {
      test('performCompression increments counters', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          service.performCompression();
          expect(service.compressions, 1);
          expect(service.currentCycleCompressions, 1);
        });
      });

      test('performVentilation increments counters', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          service.performVentilation();
          expect(service.ventilations, 1);
          expect(service.currentCycleVentilations, 1);
        });
      });

      test('performCompression no-ops when not running', () {
        service.performCompression();
        expect(service.compressions, 0);
      });

      test('performVentilation no-ops when not running', () {
        service.performVentilation();
        expect(service.ventilations, 0);
      });
    });

    group('auto-CPR', () {
      test(
          '30:2 performs 30 compressions then 2 '
          'ventilations', () {
        fakeAsync((async) {
          service.startScenario(
            Scenario.vfArrest,
            config: const TrainingConfig(
              focus: TrainingFocus.protocol,
              cprRatio: CprRatio.ratio30to2,
            ),
          );
          // 30 ticks at 545ms = 30 compressions
          async.elapse(
            const Duration(milliseconds: 545 * 30),
          );
          expect(service.compressions, 30);
          expect(service.ventilations, 0);

          // Next 2 ticks = 2 ventilations
          async.elapse(
            const Duration(milliseconds: 545 * 2),
          );
          expect(service.ventilations, 2);
        });
      });

      test(
          '15:2 performs 15 compressions then 2 '
          'ventilations', () {
        fakeAsync((async) {
          service.startScenario(
            Scenario.vfArrest,
            config: const TrainingConfig(
              focus: TrainingFocus.protocol,
              cprRatio: CprRatio.ratio15to2,
            ),
          );
          // 15 ticks at 545ms = 15 compressions
          async.elapse(
            const Duration(milliseconds: 545 * 15),
          );
          expect(service.compressions, 15);
          expect(service.ventilations, 0);

          // Next 2 ticks = 2 ventilations
          async.elapse(
            const Duration(milliseconds: 545 * 2),
          );
          expect(service.ventilations, 2);
        });
      });

      test('continuous ratio only increments compressions', () {
        fakeAsync((async) {
          service.startScenario(
            Scenario.vfArrest,
            config: const TrainingConfig(
              focus: TrainingFocus.protocol,
              cprRatio: CprRatio.continuous,
            ),
          );
          async.elapse(
            const Duration(milliseconds: 545 * 10),
          );
          expect(service.compressions, 10);
          expect(service.ventilations, 0);
        });
      });

      test('auto-CPR resets cycle at boundary', () {
        fakeAsync((async) {
          service.startScenario(
            Scenario.vfArrest,
            config: const TrainingConfig(
              focus: TrainingFocus.protocol,
              cprRatio: CprRatio.ratio30to2,
            ),
          );
          // Full cycle: 32 ticks (30 + 2)
          async.elapse(
            const Duration(milliseconds: 545 * 32),
          );
          // Next tick starts new cycle with compression
          async.elapse(const Duration(milliseconds: 545));
          expect(service.compressions, 31);
        });
      });
    });

    group('computed properties', () {
      test('cprRatio returns 0 when no ventilations', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          service.performCompression();
          expect(service.cprRatio, 0);
        });
      });

      test('cprRatio returns compressions/ventilations', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          for (var i = 0; i < 30; i++) {
            service.performCompression();
          }
          for (var i = 0; i < 2; i++) {
            service.performVentilation();
          }
          expect(service.cprRatio, 15.0);
        });
      });

      test('formattedCodeTime formats as MM:SS', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          async.elapse(const Duration(seconds: 65));
          expect(service.formattedCodeTime, '01:05');
        });
      });

      test('formattedCprCycleTime formats as MM:SS', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          async.elapse(const Duration(seconds: 130));
          expect(service.formattedCprCycleTime, '02:10');
        });
      });

      test('compressionRate returns 0 with no compressions', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          expect(service.compressionRate, 0);
        });
      });
    });

    group('defibrillation', () {
      test('chargeDefibrillator sets and clears isCharging', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          service.chargeDefibrillator();
          expect(service.isCharging, isTrue);
          async.elapse(const Duration(seconds: 3));
          expect(service.isCharging, isFalse);
        });
      });

      test('deliverShock increments shockCount', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          service.chargeDefibrillator();
          // Wait for chargeDefibrillator async to set
          // isCharging (it's set immediately before the delay)
          async.flushMicrotasks();
          service.deliverShock();
          expect(service.shockCount, 1);
        });
      });

      test('deliverShock no-ops when not charging', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          service.deliverShock();
          expect(service.shockCount, 0);
        });
      });

      test('deliverShock resets CPR cycle', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          async.elapse(const Duration(seconds: 5));
          expect(service.cprCycleSeconds, 5);

          service.chargeDefibrillator();
          async.flushMicrotasks();
          service.deliverShock();
          expect(service.cprCycleSeconds, 0);
        });
      });
    });

    group('medication administration', () {
      test('adds medication to list', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          service.administerMedication(Medication.epinephrine);
          expect(
            service.medicationsGiven,
            contains('Epinephrine 1 mg'),
          );
        });
      });

      test('records timeToFirstEpinephrine on first epi', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          async.elapse(const Duration(seconds: 120));
          service.administerMedication(Medication.epinephrine);

          final perf = service.calculatePerformance();
          expect(
            perf.metrics.timeToFirstEpinephrine,
            120,
          );
        });
      });

      test(
          'does not overwrite timeToFirstEpinephrine on '
          'second dose', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          async.elapse(const Duration(seconds: 60));
          service.administerMedication(Medication.epinephrine);
          async.elapse(const Duration(seconds: 180));
          service.administerMedication(Medication.epinephrine);

          final perf = service.calculatePerformance();
          expect(
            perf.metrics.timeToFirstEpinephrine,
            60,
          );
        });
      });

      test('no-ops when not running', () {
        service.administerMedication(Medication.epinephrine);
        expect(service.medicationsGiven, isEmpty);
      });
    });

    group('reversible causes', () {
      test('toggleReversibleCause sets cause to true', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          service.toggleReversibleCause('hypoxia');
          expect(
            service.reversibleCausesChecked['hypoxia'],
            isTrue,
          );
        });
      });

      test('toggleReversibleCause toggles back to false', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          service.toggleReversibleCause('hypoxia');
          service.toggleReversibleCause('hypoxia');
          expect(
            service.reversibleCausesChecked['hypoxia'],
            isFalse,
          );
        });
      });
    });

    group('airway management', () {
      test('setAirwayDevice updates device', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          service.setAirwayDevice('LMA');
          expect(service.airwayDevice, 'LMA');
        });
      });

      test('default airway is BVM', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          expect(service.airwayDevice, 'BVM');
        });
      });
    });

    group('pauseResume', () {
      test('toggles isRunning to false', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          service.pauseResume();
          expect(service.isRunning, isFalse);
        });
      });

      test('toggles isRunning back to true', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          service.pauseResume();
          service.pauseResume();
          expect(service.isRunning, isTrue);
        });
      });

      test('pausing stops timer increment', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          async.elapse(const Duration(seconds: 3));
          service.pauseResume();
          async.elapse(const Duration(seconds: 5));
          expect(service.codeSeconds, 3);
        });
      });

      test('resuming restarts timer', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          async.elapse(const Duration(seconds: 2));
          service.pauseResume();
          async.elapse(const Duration(seconds: 5));
          service.pauseResume();
          async.elapse(const Duration(seconds: 3));
          expect(service.codeSeconds, 5);
        });
      });
    });

    group('endScenario', () {
      test('sets isRunning to false', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          service.endScenario();
          expect(service.isRunning, isFalse);
        });
      });

      test('stops timers', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          async.elapse(const Duration(seconds: 2));
          service.endScenario();
          async.elapse(const Duration(seconds: 5));
          expect(service.codeSeconds, 2);
        });
      });
    });

    group('resetCprCycle', () {
      test('resets cycle counters', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          service.performCompression();
          service.performVentilation();
          async.elapse(const Duration(seconds: 5));

          service.resetCprCycle();
          expect(service.cprCycleSeconds, 0);
          expect(service.currentCycleCompressions, 0);
          expect(service.currentCycleVentilations, 0);
        });
      });
    });

    group('setEnergy', () {
      test('updates selected energy', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          service.setEnergy(360);
          expect(service.selectedEnergy, 360);
        });
      });

      test('default energy is 200', () {
        expect(service.selectedEnergy, 200);
      });
    });

    group('calculatePerformance', () {
      test('assembles metrics from service state', () {
        fakeAsync((async) {
          service.startScenario(Scenario.vfArrest);
          service.performCompression();
          service.performCompression();
          service.performVentilation();
          service.setAirwayDevice('ETT');
          async.elapse(const Duration(seconds: 10));

          final score = service.calculatePerformance();
          expect(score.metrics.totalCompressions, 2);
          expect(score.metrics.totalVentilations, 1);
          expect(score.metrics.airwayUsed, 'ETT');
          expect(score.metrics.totalTimeSeconds, 10);
        });
      });

      test('uses current scenario ID', () {
        fakeAsync((async) {
          service.startScenario(Scenario.peaArrest);
          final score = service.calculatePerformance();
          final ids = score.criteria.map((c) => c.id).toList();
          // PEA should not have shock criterion
          expect(ids, isNot(contains('time_to_shock')));
        });
      });
    });
  });
}
