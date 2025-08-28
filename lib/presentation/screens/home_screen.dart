import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/speech_recognition/speech_recognition_bloc.dart';
import '../bloc/verse_tracking/verse_tracking_bloc.dart';
import '../widgets/connection_status_card.dart';
import '../widgets/verse_display_card.dart';
import '../widgets/live_transcript_card.dart';
import '../widgets/control_buttons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the app
    context.read<SpeechRecognitionBloc>().add(ConnectToSTT());
    context.read<VerseTrackingBloc>().add(const LoadSurah('الفاتحة'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Tarteel'),
        centerTitle: true,
        actions: [
          BlocBuilder<SpeechRecognitionBloc, SpeechRecognitionState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  state is SpeechRecognitionConnected 
                      ? Icons.wifi 
                      : Icons.wifi_off,
                  color: state is SpeechRecognitionConnected 
                      ? Colors.white 
                      : Colors.red.shade200,
                ),
                onPressed: () {
                  if (state is! SpeechRecognitionConnected) {
                    context.read<SpeechRecognitionBloc>().add(ConnectToSTT());
                  }
                },
              );
            },
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          // Listen for speech recognition changes
          BlocListener<SpeechRecognitionBloc, SpeechRecognitionState>(
            listener: (context, state) {
              if (state is SpeechRecognitionListening && 
                  state.liveTranscript.isNotEmpty) {
                // Check verse match with live transcript
                context.read<VerseTrackingBloc>().add(
                  CheckVerseMatch(state.liveTranscript),
                );
              } else if (state is SpeechRecognitionStopped && 
                         state.finalTranscript.isNotEmpty) {
                // Final check with complete transcript
                context.read<VerseTrackingBloc>().add(
                  CheckVerseMatch(state.finalTranscript),
                );
              }
            },
          ),
          
          // Listen for verse matches
          BlocListener<VerseTrackingBloc, VerseTrackingState>(
            listener: (context, state) {
              if (state is VerseMatched) {
                _showVerseMatchedDialog(state);
              } else if (state is VerseTrackingLoaded && state.isCompleted) {
                _showCompletionDialog();
              }
            },
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Connection Status
              const ConnectionStatusCard(),
              
              const SizedBox(height: 16),
              
              // Current Verse Display
              Expanded(
                flex: 3,
                child: VerseDisplayCard(),
              ),
              
              const SizedBox(height: 16),
              
              // Live Transcript
              Expanded(
                flex: 2,
                child: LiveTranscriptCard(),
              ),
              
              const SizedBox(height: 20),
              
              // Control Buttons
              const ControlButtons(),
            ],
          ),
        ),
      ),
    );
  }

  void _showVerseMatchedDialog(VerseMatched state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 12),
            Text('آية صحيحة!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أحسنت! لقد تلوت الآية بشكل صحيح',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'دقة التلاوة: ${(state.similarity * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.matchedVerse.arabicText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('متابعة'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber, size: 35),
            SizedBox(width: 12),
            Text('مبروك!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎉 لقد أكملت سورة الفاتحة بنجاح!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'بارك الله فيك وجزاك خيراً',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Reset to start again
              context.read<VerseTrackingBloc>().add(ResetProgress());
            },
            child: const Text('إعادة البدء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    context.read<SpeechRecognitionBloc>().add(DisconnectFromSTT());
    super.dispose();
  }
}