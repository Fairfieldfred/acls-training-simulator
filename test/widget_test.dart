import 'package:flutter_test/flutter_test.dart';

import 'package:acls_simulator/main.dart';

void main() {
  testWidgets('App renders home screen', (tester) async {
    await tester.pumpWidget(const ACLSSimulatorApp());
    expect(find.text('ACLS'), findsOneWidget);
    expect(
      find.text('Training Simulator'),
      findsOneWidget,
    );
  });
}
