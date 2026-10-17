import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:court_ocr_scanner/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Court OCR Scanner app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const CourtOcrApp());
    await tester.pumpAndSettle();

    expect(find.text('Court OCR Scanner'), findsOneWidget);
    expect(find.text('Scan document'), findsOneWidget);
    expect(find.textContaining('Workbook: GH.xlsx'), findsOneWidget);
  });
}
