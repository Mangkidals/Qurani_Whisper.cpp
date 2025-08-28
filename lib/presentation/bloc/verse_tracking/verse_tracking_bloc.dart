import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../domain/entities/verse.dart';
import '../../../domain/usecases/get_surah_verses.dart';
import '../../../domain/usecases/match_verse.dart';

// Events
abstract class VerseTrackingEvent extends Equatable {
  const VerseTrackingEvent();

  @override
  List<Object> get props => [];
}

class LoadSurah extends VerseTrackingEvent {
  final String surahName;

  const LoadSurah(this.surahName);

  @override
  List<Object> get props => [surahName];
}

class CheckVerseMatch extends VerseTrackingEvent {
  final String recognizedText;

  const CheckVerseMatch(this.recognizedText);

  @override
  List<Object> get props => [recognizedText];
}

class NextVerse extends VerseTrackingEvent {}

class ResetProgress extends VerseTrackingEvent {}

// States
abstract class VerseTrackingState extends Equatable {
  const VerseTrackingState();

  @override
  List<Object> get props => [];
}

class VerseTrackingInitial extends VerseTrackingState {}

class VerseTrackingLoading extends VerseTrackingState {}

class VerseTrackingLoaded extends VerseTrackingState {
  final Surah surah;
  final int currentVerseIndex;
  final bool isCompleted;
  final String lastRecognizedText;
  final double lastSimilarity;

  const VerseTrackingLoaded({
    required this.surah,
    required this.currentVerseIndex,
    this.isCompleted = false,
    this.lastRecognizedText = '',
    this.lastSimilarity = 0.0,
  });

  Verse get currentVerse => surah.verses[currentVerseIndex];
  
  bool get hasNextVerse => currentVerseIndex < surah.verses.length - 1;

  VerseTrackingLoaded copyWith({
    Surah? surah,
    int? currentVerseIndex,
    bool? isCompleted,
    String? lastRecognizedText,
    double? lastSimilarity,
  }) {
    return VerseTrackingLoaded(
      surah: surah ?? this.surah,
      currentVerseIndex: currentVerseIndex ?? this.currentVerseIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      lastRecognizedText: lastRecognizedText ?? this.lastRecognizedText,
      lastSimilarity: lastSimilarity ?? this.lastSimilarity,
    );
  }

  @override
  List<Object> get props => [
        surah,
        currentVerseIndex,
        isCompleted,
        lastRecognizedText,
        lastSimilarity,
      ];
}

class VerseMatched extends VerseTrackingState {
  final Verse matchedVerse;
  final double similarity;

  const VerseMatched({
    required this.matchedVerse,
    required this.similarity,
  });

  @override
  List<Object> get props => [matchedVerse, similarity];
}

class VerseTrackingError extends VerseTrackingState {
  final String error;

  const VerseTrackingError(this.error);

  @override
  List<Object> get props => [error];
}

// BLoC
class VerseTrackingBloc extends Bloc<VerseTrackingEvent, VerseTrackingState> {
  final GetSurahVerses getSurahVerses;
  final MatchVerse matchVerse;

  VerseTrackingBloc({
    required this.getSurahVerses,
    required this.matchVerse,
  }) : super(VerseTrackingInitial()) {
    on<LoadSurah>(_onLoadSurah);
    on<CheckVerseMatch>(_onCheckVerseMatch);
    on<NextVerse>(_onNextVerse);
    on<ResetProgress>(_onResetProgress);
  }

  Future<void> _onLoadSurah(
    LoadSurah event,
    Emitter<VerseTrackingState> emit,
  ) async {
    emit(VerseTrackingLoading());
    
    try {
      // Add small delay to show loading state
      await Future.delayed(const Duration(milliseconds: 300));
      
      final surah = getSurahVerses(event.surahName);
      
      // Check if surah has verses
      if (surah.verses.isEmpty) {
        emit(const VerseTrackingError('Surah not found or has no verses'));
        return;
      }

      emit(VerseTrackingLoaded(
        surah: surah,
        currentVerseIndex: 0,
      ));
    } catch (e) {
      emit(VerseTrackingError('Failed to load surah: ${e.toString()}'));
    }
  }

  void _onCheckVerseMatch(
    CheckVerseMatch event,
    Emitter<VerseTrackingState> emit,
  ) {
    final currentState = state;
    if (currentState is! VerseTrackingLoaded || currentState.isCompleted) {
      return;
    }

    try {
      final currentVerse = currentState.currentVerse;
      final result = matchVerse(event.recognizedText, currentVerse);

      // Update the state with the new recognition data
      final updatedState = currentState.copyWith(
        lastRecognizedText: event.recognizedText,
        lastSimilarity: result.similarity,
      );

      // Check if verse matches
      if (result.isMatch) {
        // Check if this is the last verse
        if (updatedState.hasNextVerse) {
          // Move to next verse automatically
          final nextState = updatedState.copyWith(
            currentVerseIndex: updatedState.currentVerseIndex + 1,
            lastRecognizedText: '',
            lastSimilarity: 0.0,
          );
          emit(nextState);
        } else {
          // Mark as completed - this is the last verse
          emit(updatedState.copyWith(isCompleted: true));
        }
      } else {
        // Just update with similarity score
        emit(updatedState);
      }
    } catch (e) {
      emit(VerseTrackingError('Error matching verse: ${e.toString()}'));
    }
  }

  void _onNextVerse(
    NextVerse event,
    Emitter<VerseTrackingState> emit,
  ) {
    final currentState = state;
    if (currentState is! VerseTrackingLoaded) return;

    if (currentState.hasNextVerse) {
      emit(currentState.copyWith(
        currentVerseIndex: currentState.currentVerseIndex + 1,
        lastRecognizedText: '',
        lastSimilarity: 0.0,
      ));
    }
  }

  void _onResetProgress(
    ResetProgress event,
    Emitter<VerseTrackingState> emit,
  ) {
    final currentState = state;
    if (currentState is! VerseTrackingLoaded) return;

    emit(currentState.copyWith(
      currentVerseIndex: 0,
      isCompleted: false,
      lastRecognizedText: '',
      lastSimilarity: 0.0,
    ));
  }
}