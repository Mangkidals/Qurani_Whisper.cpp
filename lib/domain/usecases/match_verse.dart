import '../entities/verse.dart';
import '../repositories/quran_repository.dart';

class MatchVerseResult {
  final bool isMatch;
  final double similarity;

  MatchVerseResult({
    required this.isMatch,
    required this.similarity,
  });
}

class MatchVerse {
  final QuranRepository repository;

  MatchVerse(this.repository);

  MatchVerseResult call(String recognizedText, Verse targetVerse) {
    final similarity = repository.calculateSimilarity(recognizedText, targetVerse);
    final isMatch = repository.matchVerse(recognizedText, targetVerse);
    
    return MatchVerseResult(
      isMatch: isMatch,
      similarity: similarity,
    );
  }
}