import 'package:flutter_test/flutter_test.dart';
import 'package:holloway/main.dart';
import 'package:integration_test/integration_test.dart';
import 'package:holloway/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Initialize Rust library before running the test
    await RustLib.init();
    
    await tester.pumpWidget(const HollowayApp());
    await tester.pumpAndSettle();
    
    // Check that the app loads without errors
    expect(find.byType(HollowayApp), findsOneWidget);
  });
}
