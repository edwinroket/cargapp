import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:app/main.dart';
import 'package:app/providers/auth_provider.dart';

void main() {
  testWidgets('CargApp renders the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const CargApp(),
      ),
    );

    await tester.pump();

    expect(find.text('CargApp'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
