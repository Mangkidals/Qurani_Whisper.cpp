import '../../domain/entities/verse.dart';
import '../../domain/repositories/quran_repository.dart';

class QuranRepositoryImpl implements QuranRepository {
  static const Map<String, List<Map<String, String>>> _surahs = {
    'الفاتحة': [
      {
        'arabic': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        'transliteration': 'Bismillahir-Rahmanir-Rahim',
        'translation': 'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
      },
      {
        'arabic': 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
        'transliteration': 'Alhamdulillahi Rabbil-Alameen',
        'translation': 'All praise is due to Allah, Lord of the worlds.',
      },
      {
        'arabic': 'الرَّحْمَٰنِ الرَّحِيمِ',
        'transliteration': 'Ar-Rahmanir-Rahim',
        'translation': 'The Entirely Merciful, the Especially Merciful,',
      },
      {
        'arabic': 'مَالِكِ يَوْمِ الدِّينِ',
        'transliteration': 'Maliki Yawmid-Deen',
        'translation': 'Sovereign of the Day of Recompense.',
      },
      {
        'arabic': 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
        'transliteration': 'Iyyaka Na\'budu wa Iyyaka Nasta\'een',
        'translation': 'It is You we worship and You we ask for help.',
      },
      {
        'arabic': 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
        'transliteration': 'Ihdinassiratal-Mustaqeem',
        'translation': 'Guide us to the straight path.',
      },
      {
        'arabic': 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
        'transliteration': 'Siratal-Latheena An\'amta \'alayhim Ghayril-Maghdoobi \'alayhim wa lad-Dalleen',
        'translation': 'The path of those upon whom You have bestowed favor, not of those who have evoked Your anger or of those who are astray.',
      },
    ],
  };

  @override
  Surah getSurah(String surahName) {
    final surahData = _surahs[surahName] ?? [];
    final verses = surahData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return Verse(
        number: index + 1,
        arabicText: data['arabic'] ?? '',
        transliteration: data['transliteration'] ?? '',
        translation: data['translation'] ?? '',
      );
    }).toList();

    return Surah(name: surahName, verses: verses);
  }

  @override
  bool matchVerse(String recognizedText, Verse targetVerse) {
    final similarity = calculateSimilarity(recognizedText, targetVerse);
    return similarity > 0.6; // 60% similarity threshold
  }

  @override
  double calculateSimilarity(String recognizedText, Verse targetVerse) {
    if (recognizedText.isEmpty || targetVerse.arabicText.isEmpty) {
      return 0.0;
    }

    final recognizedWords = _normalizeArabicText(recognizedText).split(' ');
    final targetWords = _normalizeArabicText(targetVerse.arabicText).split(' ');

    if (recognizedWords.isEmpty || targetWords.isEmpty) {
      return 0.0;
    }

    int matchedWords = 0;
    for (final recognizedWord in recognizedWords) {
      if (recognizedWord.length < 2) continue; // Skip very short words
      
      for (final targetWord in targetWords) {
        if (_wordSimilarity(recognizedWord, targetWord) > 0.7) {
          matchedWords++;
          break;
        }
      }
    }

    return matchedWords / targetWords.length;
  }

  String _normalizeArabicText(String text) {
    return text
        .replaceAll(RegExp(r'[َُِّْ]'), '') // Remove diacritics
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim()
        .toLowerCase();
  }

  double _wordSimilarity(String word1, String word2) {
    if (word1 == word2) return 1.0;
    if (word1.length < 2 || word2.length < 2) return 0.0;

    // Check if one word contains the other
    if (word1.contains(word2) || word2.contains(word1)) {
      return 0.8;
    }

    // Simple Levenshtein distance approximation
    final shorter = word1.length < word2.length ? word1 : word2;
    final longer = word1.length < word2.length ? word2 : word1;

    int matches = 0;
    for (int i = 0; i < shorter.length; i++) {
      if (i < longer.length && shorter[i] == longer[i]) {
        matches++;
      }
    }

    return matches / longer.length;
  }
}