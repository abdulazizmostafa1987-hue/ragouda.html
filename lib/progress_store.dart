import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressStore {
  ProgressStore(this._p);
  final SharedPreferences _p;

  static Future<ProgressStore> open() async =>
      ProgressStore(await SharedPreferences.getInstance());

  int get xp => _p.getInt('xp') ?? 0;
  int get level => xp ~/ 100 + 1;
  String? get lastLesson => _p.getString('lastLesson');
  Set<String> get wrongIds => (_p.getStringList('wrong') ?? []).toSet();
  List<Map<String, dynamic>> get attempts =>
      (_p.getStringList('attempts') ?? [])
          .map((s) => jsonDecode(s) as Map<String, dynamic>)
          .toList();

  Future<void> setLastLesson(String id) => _p.setString('lastLesson', id);

  Future<void> recordAttempt({
    required String lessonId,
    required int correct,
    required int total,
    required Set<String> wrong,
    required Set<String> right,
  }) async {
    await _p.setInt('xp', xp + correct * 10);
    final w = wrongIds..addAll(wrong)..removeAll(right);
    await _p.setStringList('wrong', w.toList());
    final list = _p.getStringList('attempts') ?? [];
    list.add(jsonEncode({
      'lesson': lessonId,
      'correct': correct,
      'total': total,
      'at': DateTime.now().toIso8601String(),
    }));
    await _p.setStringList('attempts', list);
  }
}
