import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/models/inputs.dart';
import 'package:my_app/services/wellness_risk_calculator.dart';

void main() {
  test('low sleep and heavy study flags high risk', () {
    final risk = WellnessRiskCalculator.calculate(
      trainingLoad: 0,
      sleepHours: 5,
      studyHours: 10,
    );

    expect(risk, CrashRisk.high);
  });

  test('healthy balance stays low risk', () {
    final risk = WellnessRiskCalculator.calculate(
      trainingLoad: 4,
      sleepHours: 8,
      studyHours: 2,
    );

    expect(risk, CrashRisk.low);
  });

  test('moderate strain flags moderate risk', () {
    final risk = WellnessRiskCalculator.calculate(
      trainingLoad: 3,
      sleepHours: 7.2,
      studyHours: 5,
    );

    expect(risk, CrashRisk.moderate);
  });
}
