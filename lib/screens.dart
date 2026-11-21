import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';
import 'progress_store.dart';
import 'quiz_engine.dart';

class Shell extends StatefulWidget {
  const Shell({super.key, required this.store, required this.content});
  final ProgressStore store;
  final Content content;
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(store: widget.store, content: widget.content, onChanged: _refresh),
      LibraryPage(store: widget.store, content: widget.content, onChanged: _refresh),
      AchievementsPage(store: widget.store),
      GamesPage(content: widget.content),
      AccountPage(store: widget.store, content: widget.content, onChanged: _refresh),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('رغد – رحلتي نحو التفوق')),
      body: pages[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'المكتبة'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'إنجازاتي'),
          NavigationDestination(icon: Icon(Icons.extension_outlined), label: 'الألعاب'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'حسابي'),
        ],
      ),
    );
  }
}

Lesson? _findLesson(Content c, String? id) {
  for (final s in c.subjects) {
    for (final l in s.lessons) {
      if (l.id == id) return l;
    }
  }
  return null;
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.store, required this.content, required this.onChanged});
  final ProgressStore store;
  final Content content;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final last = _findLesson(content, store.lastLesson);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('أهلًا يا رغد 👋', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: const Icon(Icons.star),
          title: Text('المستوى ${store.level}'),
          subtitle: Text('نقاط الخبرة: ${store.xp}'),
        ),
      ),
      if (last != null)
        Card(
          child: ListTile(
            leading: const Icon(Icons.play_circle),
            title: const Text('استكمل من حيث توقفت'),
            subtitle: Text(last.title),
            onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => LessonPage(lesson: last, store: store)))
                .then((_) => onChanged()),
          ),
        ),
      if (content.isSample)
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('المحتوى الحالي تجريبي'),
            subtitle: Text('لم يُعتمد بعد من المنهج الرسمي.'),
          ),
        ),
    ]);
  }
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key, required this.store, required this.content, required this.onChanged});
  final ProgressStore store;
  final Content content;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      for (final s in content.subjects)
        ExpansionTile(
          title: Text(s.name),
          initiallyExpanded: true,
          children: [
            for (final l in s.lessons)
              ListTile(
                title: Text(l.title),
                trailing: const Icon(Icons.chevron_left),
                onTap: () async {
                  await store.setLastLesson(l.id);
                  if (!context.mounted) return;
                  await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                          builder: (_) => LessonPage(lesson: l, store: store)));
                  onChanged();
                },
              ),
          ],
        ),
    ]);
  }
}

class LessonPage extends StatelessWidget {
  const LessonPage({super.key, required this.lesson, required this.store});
  final Lesson lesson;
  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('أهداف التعلم', style: Theme.of(context).textTheme.titleMedium),
        for (final o in lesson.objectives) Text('• $o'),
        const SizedBox(height: 16),
        Text('الشرح', style: Theme.of(context).textTheme.titleMedium),
        Text(lesson.body, style: const TextStyle(fontSize: 18, height: 1.7)),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.quiz),
          label: const Text('اختبار قصير'),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => QuizPage(
                      lessonId: lesson.id,
                      questions: lesson.questions,
                      store: store))),
        ),
      ]),
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key, required this.lessonId, required this.questions, required this.store});
  final String lessonId;
  final List<Question> questions;
  final ProgressStore store;
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late final List<Question> _qs = QuizEngine.prepare(widget.questions);
  int _n = 0;
  int? _chosen;
  final Set<String> _wrong = {};
  final Set<String> _right = {};
  bool _done = false;

  Future<void> _next() async {
    if (_n + 1 < _qs.length) {
      setState(() {
        _n++;
        _chosen = null;
      });
      return;
    }
    await widget.store.recordAttempt(
        lessonId: widget.lessonId,
        correct: _right.length,
        total: _qs.length,
        wrong: _wrong,
        right: _right);
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_qs.isEmpty) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('لا توجد أسئلة.')));
    }
    if (_done) {
      final p = QuizEngine.percent(_right.length, _qs.length);
      return Scaffold(
        appBar: AppBar(title: const Text('النتيجة')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$p٪', style: Theme.of(context).textTheme.displayMedium),
            Text('أجبتِ ${_right.length} من ${_qs.length} بشكل صحيح'),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('رجوع')),
          ]),
        ),
      );
    }
    final q = _qs[_n];
    return Scaffold(
      appBar: AppBar(title: Text('سؤال ${_n + 1} من ${_qs.length}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(q.text, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 12),
        for (var i = 0; i < q.options.length; i++)
          Card(
            color: _chosen == null
                ? null
                : i == q.answer
                    ? Colors.green.withValues(alpha: 0.25)
                    : i == _chosen
                        ? Colors.orange.withValues(alpha: 0.25)
                        : null,
            child: ListTile(
              title: Text(q.options[i]),
              onTap: _chosen != null
                  ? null
                  : () {
                      final ok = QuizEngine.isCorrect(q, i);
                      setState(() {
                        _chosen = i;
                        (ok ? _right : _wrong).add(q.id);
                      });
                    },
            ),
          ),
        if (_chosen != null) ...[
          Text(_chosen == q.answer ? 'أحسنتِ! 🌟' : 'قريبة! راجعي التفسير:'),
          Text(q.explanation),
          const SizedBox(height: 12),
          FilledButton(onPressed: _next, child: const Text('التالي')),
        ],
      ]),
    );
  }
}

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key, required this.store});
  final ProgressStore store;
  @override
  Widget build(BuildContext context) {
    final a = store.attempts.reversed.toList();
    if (a.isEmpty) {
      return const Center(child: Text('ابدئي أول اختبار لتظهر إنجازاتك هنا.'));
    }
    return ListView(children: [
      for (final x in a)
        ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: Text('${x['correct']} / ${x['total']}'),
          subtitle: Text('${x['lesson']}'),
        ),
    ]);
  }
}

class GamesPage extends StatelessWidget {
  const GamesPage({super.key, required this.content});
  final Content content;
  @override
  Widget build(BuildContext context) => ListView(children: [
        ListTile(
          leading: const Icon(Icons.grid_view),
          title: const Text('لعبة الذاكرة'),
          subtitle: const Text('طابقي الكسر مع قيمته العشرية'),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => MemoryGamePage(pairs: content.pairs))),
        ),
      ]);
}

class _MCard {
  _MCard(this.pair, this.label);
  final int pair;
  final String label;
  bool open = false;
  bool matched = false;
}

class MemoryGamePage extends StatefulWidget {
  const MemoryGamePage({super.key, required this.pairs});
  final List<List<String>> pairs;
  @override
  State<MemoryGamePage> createState() => _MemoryGamePageState();
}

class _MemoryGamePageState extends State<MemoryGamePage> {
  late final List<_MCard> _cards = _build();
  int? _first;
  bool _lock = false;

  List<_MCard> _build() {
    final l = <_MCard>[];
    for (var i = 0; i < widget.pairs.length; i++) {
      l.add(_MCard(i, widget.pairs[i][0]));
      l.add(_MCard(i, widget.pairs[i][1]));
    }
    return l..shuffle(Random());
  }

  Future<void> _tap(int i) async {
    final c = _cards[i];
    if (_lock || c.open || c.matched) return;
    setState(() => c.open = true);
    if (_first == null) {
      _first = i;
      return;
    }
    final f = _cards[_first!];
    _first = null;
    if (f.pair == c.pair) {
      setState(() {
        f.matched = true;
        c.matched = true;
      });
    } else {
      _lock = true;
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        f.open = false;
        c.open = false;
      });
      _lock = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final won = _cards.every((c) => c.matched);
    return Scaffold(
      appBar: AppBar(title: Text(won ? 'أحسنتِ! أنهيتِ اللعبة 🎉' : 'لعبة الذاكرة')),
      body: GridView.count(
        crossAxisCount: 4,
        padding: const EdgeInsets.all(12),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (var i = 0; i < _cards.length; i++)
            InkWell(
              onTap: () => _tap(i),
              child: Card(
                color: _cards[i].matched ? Colors.green.withValues(alpha: 0.3) : null,
                child: Center(
                    child: Text(
                        _cards[i].open || _cards[i].matched ? _cards[i].label : '؟',
                        style: const TextStyle(fontSize: 18))),
              ),
            ),
        ],
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key, required this.store, required this.content, required this.onChanged});
  final ProgressStore store;
  final Content content;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    final wrong = store.wrongIds;
    final review = <Question>[
      for (final s in content.subjects)
        for (final l in s.lessons)
          for (final q in l.questions)
            if (wrong.contains(q.id)) q
    ];
    return ListView(padding: const EdgeInsets.all(16), children: [
      ListTile(
        leading: const Icon(Icons.replay),
        title: const Text('مراجعة أخطائي'),
        subtitle: Text('${review.length} سؤال'),
        enabled: review.isNotEmpty,
        onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) => QuizPage(
                        lessonId: 'review', questions: review, store: store)))
            .then((_) => onChanged()),
      ),
    ]);
  }
}
