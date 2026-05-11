import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PageInsights {
  final String text;
  final int wordCount;
  final int sentenceCount;
  final String readingTime;
  final String difficulty;
  final String difficultyEmoji;
  final String summary;
  final List<String> keyPoints;

  const PageInsights({
    required this.text,
    required this.wordCount,
    required this.sentenceCount,
    required this.readingTime,
    required this.difficulty,
    required this.difficultyEmoji,
    required this.summary,
    required this.keyPoints,
  });

  bool get hasText => text.isNotEmpty;

  static PageInsights empty() => const PageInsights(
        text: '',
        wordCount: 0,
        sentenceCount: 0,
        readingTime: '—',
        difficulty: '—',
        difficultyEmoji: '📄',
        summary: '',
        keyPoints: [],
      );
}

class InsightsService {
  static final InsightsService instance = InsightsService._();
  InsightsService._();

  // ── Text extraction ────────────────────────────────────────────────────────

  Future<String> extractPageText(String filePath, int pageNumber) async {
    try {
      final bytes = await File(filePath).readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(doc);
      final text = extractor.extractText(
        startPageIndex: pageNumber - 1,
        endPageIndex: pageNumber - 1,
      );
      doc.dispose();
      return text.trim();
    } catch (_) {
      return '';
    }
  }

  // ── Full page analysis (instant — pure Dart) ───────────────────────────────

  PageInsights analyze(String text) {
    if (text.trim().isEmpty) return PageInsights.empty();

    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final sentences = _splitSentences(cleaned);
    final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    final wordCount = words.length;
    final sentenceCount = sentences.length.clamp(1, 99999);

    // Reading time (230 WPM average)
    final minutes = wordCount / 230.0;
    final readingTime = minutes < 0.5
        ? '< 1 min'
        : minutes < 1.5
            ? '~1 min'
            : '~${minutes.round()} min';

    // Difficulty (avg word length + avg sentence length)
    final avgWordLen =
        words.fold(0, (s, w) => s + w.replaceAll(RegExp(r'[^a-zA-Z]'), '').length) /
            wordCount.clamp(1, 99999);
    final avgSentLen = wordCount / sentenceCount;
    final diffScore = (avgWordLen * 0.5) + (avgSentLen * 0.1);
    final (difficulty, difficultyEmoji) = diffScore < 4.5
        ? ('Easy', '🟢')
        : diffScore < 5.5
            ? ('Moderate', '🟡')
            : diffScore < 6.5
                ? ('Challenging', '🟠')
                : ('Advanced', '🔴');

    final summary = _extractiveSummary(sentences, count: 4);
    final keyPoints = _keyPoints(sentences, count: 5);

    return PageInsights(
      text: cleaned,
      wordCount: wordCount,
      sentenceCount: sentenceCount,
      readingTime: readingTime,
      difficulty: difficulty,
      difficultyEmoji: difficultyEmoji,
      summary: summary,
      keyPoints: keyPoints,
    );
  }

  // ── Find relevant sentences for a question ────────────────────────────────

  List<String> findRelevant(String text, String query) {
    if (query.trim().isEmpty) return [];
    final sentences = _splitSentences(text);
    if (sentences.isEmpty) return [];

    final qWords = query.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 2).toSet();
    final scores = <int, double>{};
    for (int i = 0; i < sentences.length; i++) {
      final sWords = sentences[i].toLowerCase().split(RegExp(r'\W+')).toSet();
      final overlap = qWords.intersection(sWords).length;
      if (overlap > 0) scores[i] = overlap / qWords.length;
    }
    if (scores.isEmpty) return [];

    return (scores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(3)
        .map((e) => sentences[e.key].trim())
        .toList();
  }

  // ── Extractive helpers ─────────────────────────────────────────────────────

  List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.split(' ').length >= 5)
        .toList();
  }

  Map<int, double> _scoreByFrequency(List<String> sentences) {
    const stopWords = {
      'the','a','an','is','are','was','were','be','been','have','has','had',
      'do','does','did','will','would','could','should','may','might','to',
      'of','in','for','on','with','at','by','from','and','but','or','not',
      'it','its','this','that','he','she','they','we','you','i','me','him',
      'her','us','them','my','your','his','their','our','what','which','who',
      'when','where','how','all','each','more','some','so','then','than',
      'as','if','into','up','out','about','also','just','very',
    };
    final freq = <String, int>{};
    for (final s in sentences) {
      for (final w in s.toLowerCase().split(RegExp(r'\W+'))) {
        if (w.length > 3 && !stopWords.contains(w)) {
          freq[w] = (freq[w] ?? 0) + 1;
        }
      }
    }
    final scores = <int, double>{};
    for (int i = 0; i < sentences.length; i++) {
      final words = sentences[i].toLowerCase().split(RegExp(r'\W+'));
      double score = 0;
      for (final w in words) {
        score += freq[w] ?? 0;
      }
      score /= words.length.clamp(1, 9999);
      // Boost opening sentences — usually establish the key idea
      if (i == 0) score *= 1.6;
      if (i == 1) score *= 1.2;
      scores[i] = score;
    }
    return scores;
  }

  String _extractiveSummary(List<String> sentences, {required int count}) {
    if (sentences.isEmpty) return '';
    if (sentences.length <= count) return sentences.join(' ');
    final scores = _scoreByFrequency(sentences);
    final top = (scores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(count)
        .map((e) => e.key)
        .toList()
      ..sort();
    return top.map((i) => sentences[i]).join(' ');
  }

  List<String> _keyPoints(List<String> sentences, {required int count}) {
    if (sentences.isEmpty) return [];
    final scores = _scoreByFrequency(sentences);
    return (scores.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(count)
        .map((e) => sentences[e.key].trim())
        .toList();
  }
}
