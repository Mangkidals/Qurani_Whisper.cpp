import '../entities/verse.dart';
import '../repositories/quran_repository.dart';

class GetSurahVerses {
  final QuranRepository repository;

  GetSurahVerses(this.repository);

  Surah call(String surahName) {
    return repository.getSurah(surahName);
  }
}