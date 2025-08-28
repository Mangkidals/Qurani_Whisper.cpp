import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/di/dependency_injection.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/bloc/speech_recognition/speech_recognition_bloc.dart';
import 'presentation/bloc/verse_tracking/verse_tracking_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await DependencyInjection.init();
  
  runApp(const MiniTarteelApp());
}

class MiniTarteelApp extends StatelessWidget {
  const MiniTarteelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Tarteel',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Arial',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => GetIt.instance<SpeechRecognitionBloc>(),
          ),
          BlocProvider(
            create: (context) => GetIt.instance<VerseTrackingBloc>(),
          ),
        ],
        child: const HomeScreen(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}