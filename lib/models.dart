import 'dart:convert';
import 'package:flutter/services.dart';

class Question {
  const Question({
    required this.id,
    required this.type,
    required this.text,
    required this.options,
    required this.answer,
    required this.difficulty,
    required this.explanation,
  });

  final String id;
  final String type;
  final String text;
  final List<String> options;
  final int answer;
  final int difficulty;
  final String explanation;

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: j['id'] as String,
        type: j['type'] as String,
        text: j['text'] as String,
        options: List<String>.from(j['options'] as List),
        answer: j['answer'] as int,
        difficulty: (j['difficulty'] ?? 1) as int,
        explanation: (j['explanation'] ?? '') as String,
      );
}

class Lesson {
  const Lesson(this.id, this.title, this.objectives, this.body, this.questions);
  final String id;
  final String title;
  final List<String> objectives;
  final String body;
  final List<Question> questions;

  factory Lesson.fromJson(Map<String, dynamic> j) => Lesson(
        j['id'] as String,
        j['title'] as String,
        List<String>.from(j['objectives'] as List),
        j['body'] as String,
        (j['questions'] as List)
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Subject {
  const Subject(this.id, this.name, this.lessons);
  final String id;
  final String name;
  final List<Lesson> lessons;
}

class Content {
  const Content(this.isSample, this.subjects, this.pairs);
  final bool isSample;
  final List<Subject> subjects;
  final List<List<String>> pairs;

  static Future<Content> load() async {
    final raw = await rootBundle.loadString('assets/content/sample_content.json');
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final subjects = (j['subjects'] as List).map((s) {
      final m = s as Map<String, dynamic>;
      return Subject(
        m['id'] as String,
        m['name'] as String,
        (m['lessons'] as List)
            .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
            .toList(),
      );
    }).toList();
    final pairs = (j['memoryPairs'] as List).map((p) {
      final m = p as Map<String, dynamic>;
      return <String>[m['a'] as String, m['b'] as String];
    }).toList();
    return Content((j['sample'] ?? false) as bool, subjects, pairs);
  }
}
