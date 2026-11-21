import 'dart:math';
import 'models.dart';

class QuizEngine {
  /// يخلط ترتيب الأسئلة والاختيارات مع الحفاظ على الإجابة الصحيحة.
  static List<Question> prepare(List<Question> source, {Random? rng}) {
    final r = rng ?? Random();
    final qs = [...source]..shuffle(r);
    return qs.map((q) {
      if (q.type == 'tf') return q;
      final idx = List<int>.generate(q.options.length, (i) => i)..shuffle(r);
      return Question(
        id: q.id,
        type: q.type,
        text: q.text,
        options: idx.map((i) => q.options[i]).toList(),
        answer: idx.indexOf(q.answer),
        difficulty: q.difficulty,
        explanation: q.explanation,
      );
    }).toList();
  }

  static bool isCorrect(Question q, int chosen) => q.answer == chosen;

  static int percent(int correct, int total) =>
      total == 0 ? 0 : ((correct * 100) / total).round();
}
