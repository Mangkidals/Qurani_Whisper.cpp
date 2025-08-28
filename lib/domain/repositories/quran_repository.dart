import '../entities/verse.dart';

abstract class QuranRepository {
  Surah getSurah(String surahName);
  bool matchVerse(String recognizedText, Verse targetVerse);
  double calculateSimilarity(String recognizedText, Verse targetVerse);
}