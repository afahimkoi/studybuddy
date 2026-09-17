import 'package:flutter_test/flutter_test.dart';
import 'package:studybuddy/main.dart';

void main() {
  testWidgets('login screen is displayed for a signed-out user', (tester) async {
    final model = StudyModel();
    await tester.pumpWidget(StudyBuddy(model: model));
    expect(find.text('StudyBuddy'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });
}
