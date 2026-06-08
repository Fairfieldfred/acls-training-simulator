import 'package:flutter_test/flutter_test.dart';
import 'package:acls_simulator/models/training_config.dart';

void main() {
  group('CprRatio', () {
    group('displayName', () {
      test('ratio30to2 returns 30:2', () {
        expect(CprRatio.ratio30to2.displayName, '30:2');
      });

      test('ratio15to2 returns 15:2', () {
        expect(CprRatio.ratio15to2.displayName, '15:2');
      });

      test('continuous returns Continuous', () {
        expect(CprRatio.continuous.displayName, 'Continuous');
      });
    });

    group('targetRatio', () {
      test('ratio30to2 returns 15.0', () {
        expect(CprRatio.ratio30to2.targetRatio, 15.0);
      });

      test('ratio15to2 returns 7.5', () {
        expect(CprRatio.ratio15to2.targetRatio, 7.5);
      });

      test('continuous returns 0', () {
        expect(CprRatio.continuous.targetRatio, 0);
      });
    });

    group('acceptableRange', () {
      test('ratio30to2 returns (13.0, 17.0)', () {
        final (min, max) = CprRatio.ratio30to2.acceptableRange;
        expect(min, 13.0);
        expect(max, 17.0);
      });

      test('ratio15to2 returns (6.0, 9.0)', () {
        final (min, max) = CprRatio.ratio15to2.acceptableRange;
        expect(min, 6.0);
        expect(max, 9.0);
      });

      test('continuous returns (0, 0)', () {
        final (min, max) = CprRatio.continuous.acceptableRange;
        expect(min, 0);
        expect(max, 0);
      });
    });

    group('compressions and ventilations', () {
      test('ratio30to2 has 30 compressions and 2 ventilations', () {
        expect(CprRatio.ratio30to2.compressions, 30);
        expect(CprRatio.ratio30to2.ventilations, 2);
      });

      test('ratio15to2 has 15 compressions and 2 ventilations', () {
        expect(CprRatio.ratio15to2.compressions, 15);
        expect(CprRatio.ratio15to2.ventilations, 2);
      });

      test('continuous has 0 compressions and 0 ventilations', () {
        expect(CprRatio.continuous.compressions, 0);
        expect(CprRatio.continuous.ventilations, 0);
      });
    });
  });

  group('TrainingConfig', () {
    test('defaults to timing mode with 30:2 ratio', () {
      const config = TrainingConfig();
      expect(config.focus, TrainingFocus.timing);
      expect(config.cprRatio, CprRatio.ratio30to2);
    });

    test('isTimingMode returns true for timing focus', () {
      const config = TrainingConfig(focus: TrainingFocus.timing);
      expect(config.isTimingMode, isTrue);
      expect(config.isProtocolMode, isFalse);
    });

    test('isProtocolMode returns true for protocol focus', () {
      const config = TrainingConfig(focus: TrainingFocus.protocol);
      expect(config.isProtocolMode, isTrue);
      expect(config.isTimingMode, isFalse);
    });
  });
}
