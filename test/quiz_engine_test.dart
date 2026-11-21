import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:raghad/models.dart';
import 'package:raghad/quiz_engine.dart';

void main() {
  const q = Question(
      id: 'a',
      type: 'mcq',
      text: 't',
      options: ['x', 'y', 'z', 'w'],
      answer: 2,
      difficulty: 1,
      explanation: '');

  test('الخلط يحافظ على الإجابة الصحيحة', () {
    for (var seed = 0; seed < 50; seed++) {
      final r = QuizEngine.prepare([q], rng: Random(seed)).first;
      expect(r.options[r.answer], 'z');
    }
  });

  test('حساب النسبة', () {
    expect(QuizEngine.percent(2, 3), 67);
    expect(QuizEngine.percent(0, 0), 0);
  });

  test('التصحيح', () {
    expect(QuizEngine.isCorrect(q, 2), true);
    expect(QuizEngine.isCorrect(q, 1), false);
  });
}
