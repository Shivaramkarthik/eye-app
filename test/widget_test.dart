import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:specz_co/models/prescription_model.dart';
import 'package:specz_co/models/user_model.dart';
import 'package:specz_co/services/entitlement_service.dart';
import 'package:specz_co/widgets/eye_health_score_card.dart';

void main() {
  testWidgets('EyeHealthScoreCard renders score and reasoning', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EyeHealthScoreCard(
            score: 85,
            explanation: 'Prescription is up to date.',
          ),
        ),
      ),
    );

    expect(find.textContaining('85 / 100'), findsOneWidget);
    expect(find.textContaining('Prescription is up to date.'), findsOneWidget);
  });

  test('UserModel profile limits test', () {
    final freeUser = UserModel(id: 'u1', email: 'a@b.com', name: 'User 1', plan: 'free', status: 'free', createdAt: '2026-08-09');
    expect(freeUser.maxProfiles, 1);

    final plusUser = UserModel(id: 'u2', email: 'c@d.com', name: 'User 2', plan: 'plus', status: 'active', createdAt: '2026-08-09');
    expect(plusUser.maxProfiles, 5);
    expect(EntitlementService.instance.canGeneratePdf(plusUser), true);
  });

  test('Prescription missing SPH/CYL warning test', () {
    final complete = PrescriptionModel(
      id: 'p1',
      profileId: 'prof1',
      userId: 'u1',
      prescriptionDate: '2026-08-09',
      rightSph: -2.0,
      rightCyl: -0.5,
      leftSph: -2.0,
      leftCyl: -0.5,
      createdAt: '2026-08-09',
    );
    expect(complete.isMissingSphOrCyl, false);

    final missing = PrescriptionModel(
      id: 'p2',
      profileId: 'prof1',
      userId: 'u1',
      prescriptionDate: '2026-08-09',
      rightSph: null,
      rightCyl: -0.5,
      leftSph: -2.0,
      leftCyl: null,
      createdAt: '2026-08-09',
    );
    expect(missing.isMissingSphOrCyl, true);
  });
}
