import 'package:get_it/get_it.dart';

import '../../data/repositories/quran_repository_impl.dart';
import '../../data/services/audio_service.dart';
import '../../data/services/vosk_service.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/usecases/get_surah_verses.dart';
import '../../domain/usecases/match_verse.dart';
import '../../presentation/bloc/speech_recognition/speech_recognition_bloc.dart';
import '../../presentation/bloc/verse_tracking/verse_tracking_bloc.dart';

class DependencyInjection {
  static final GetIt _getIt = GetIt.instance;

  static Future<void> init() async {
    // Services
    _getIt.registerLazySingleton<VoskService>(() => VoskService());
    _getIt.registerLazySingleton<AudioService>(() => AudioService());

    // Repositories
    _getIt.registerLazySingleton<QuranRepository>(
      () => QuranRepositoryImpl(),
    );

    // Use Cases
    _getIt.registerLazySingleton<GetSurahVerses>(
      () => GetSurahVerses(_getIt<QuranRepository>()),
    );
    _getIt.registerLazySingleton<MatchVerse>(
      () => MatchVerse(_getIt<QuranRepository>()),
    );

    // BLoCs
    _getIt.registerFactory<SpeechRecognitionBloc>(
      () => SpeechRecognitionBloc(
        voskService: _getIt<VoskService>(),
        audioService: _getIt<AudioService>(),
      ),
    );
    _getIt.registerFactory<VerseTrackingBloc>(
      () => VerseTrackingBloc(
        getSurahVerses: _getIt<GetSurahVerses>(),
        matchVerse: _getIt<MatchVerse>(),
      ),
    );
  }
}