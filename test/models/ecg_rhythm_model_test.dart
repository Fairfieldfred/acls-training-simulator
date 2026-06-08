import 'package:flutter_test/flutter_test.dart';
import 'package:acls_simulator/models/ecg_rhythm_model.dart';

void main() {
  group('ECGRhythm', () {
    group('isShockable', () {
      test('vf is shockable', () {
        expect(ECGRhythm.vf.isShockable, isTrue);
      });

      test('pvt is shockable', () {
        expect(ECGRhythm.pvt.isShockable, isTrue);
      });

      test('pea is not shockable', () {
        expect(ECGRhythm.pea.isShockable, isFalse);
      });

      test('asystole is not shockable', () {
        expect(ECGRhythm.asystole.isShockable, isFalse);
      });

      test('normalSinus is not shockable', () {
        expect(ECGRhythm.normalSinus.isShockable, isFalse);
      });
    });

    group('heartRate', () {
      test('vf has heart rate 0', () {
        expect(ECGRhythm.vf.heartRate, 0);
      });

      test('pvt has heart rate 180', () {
        expect(ECGRhythm.pvt.heartRate, 180);
      });

      test('pea has heart rate 60', () {
        expect(ECGRhythm.pea.heartRate, 60);
      });

      test('asystole has heart rate 0', () {
        expect(ECGRhythm.asystole.heartRate, 0);
      });

      test('normalSinus has heart rate 75', () {
        expect(ECGRhythm.normalSinus.heartRate, 75);
      });
    });

    group('displayName', () {
      test('vf displays Ventricular Fibrillation', () {
        expect(
          ECGRhythm.vf.displayName,
          'Ventricular Fibrillation',
        );
      });

      test('pvt displays Pulseless V-Tach', () {
        expect(ECGRhythm.pvt.displayName, 'Pulseless V-Tach');
      });

      test('pea displays PEA', () {
        expect(ECGRhythm.pea.displayName, 'PEA');
      });

      test('asystole displays Asystole', () {
        expect(ECGRhythm.asystole.displayName, 'Asystole');
      });

      test('normalSinus displays Normal Sinus Rhythm', () {
        expect(
          ECGRhythm.normalSinus.displayName,
          'Normal Sinus Rhythm',
        );
      });
    });
  });
}
