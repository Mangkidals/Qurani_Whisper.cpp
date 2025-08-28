import 'package:equatable/equatable.dart';

class Verse extends Equatable {
  final int number;
  final String arabicText;
  final String transliteration;
  final String translation;

  const Verse({
    required this.number,
    required this.arabicText,
    required this.transliteration,
    required this.translation,
  });

  @override
  List<Object?> get props => [number, arabicText, transliteration, translation];
}

class Surah extends Equatable {
  final String name;
  final List<Verse> verses;

  const Surah({
    required this.name,
    required this.verses,
  });

  @override
  List<Object?> get props => [name, verses];
}