import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/speech_recognition/speech_recognition_bloc.dart';
import '../bloc/verse_tracking/verse_tracking_bloc.dart';

class ControlButtons extends StatelessWidget {
  const ControlButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpeechRecognitionBloc, SpeechRecognitionState>(
      builder: (context, speechState) {
        return BlocBuilder<VerseTrackingBloc, VerseTrackingState>(
          builder: (context, verseState) {
            final bool isConnected = speechState is SpeechRecognitionConnected ||
                                   speechState is SpeechRecognitionListening ||
                                   speechState is SpeechRecognitionStopped;
            
            final bool isListening = speechState is SpeechRecognitionListening;
            
            final bool canStart = isConnected && !isListening && 
                                 verseState is VerseTrackingLoaded && 
                                 !verseState.isCompleted;
            
            return Column(
              children: [
                // Main control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Reset button
                    _buildControlButton(
                      onPressed: verseState is VerseTrackingLoaded
                          ? () {
                              // Stop listening first if active
                              if (isListening) {
                                context.read<SpeechRecognitionBloc>().add(StopListening());
                              }
                              // Reset verse progress
                              context.read<VerseTrackingBloc>().add(ResetProgress());
                            }
                          : null,
                      icon: Icons.refresh,
                      label: 'إعادة تعيين',
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    
                    // Main recording button
                    _buildMainButton(
                      context: context,
                      isListening: isListening,
                      canStart: canStart,
                      speechState: speechState,
                    ),
                    
                    // Connection button
                    _buildControlButton(
                      onPressed: () {
                        if (isConnected) {
                          context.read<SpeechRecognitionBloc>().add(DisconnectFromSTT());
                        } else {
                          context.read<SpeechRecognitionBloc>().add(ConnectToSTT());
                        }
                      },
                      icon: isConnected ? Icons.wifi_off : Icons.wifi,
                      label: isConnected ? 'قطع الاتصال' : 'اتصال',
                      backgroundColor: isConnected ? Colors.red.shade600 : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ],
                ),
                
                // Status text
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusMessage(speechState, verseState),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMainButton({
    required BuildContext context,
    required bool isListening,
    required bool canStart,
    required SpeechRecognitionState speechState,
  }) {
    return GestureDetector(
      onTap: canStart || isListening
          ? () {
              if (isListening) {
                context.read<SpeechRecognitionBloc>().add(StopListening());
              } else {
                context.read<SpeechRecognitionBloc>().add(StartListening());
              }
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: _getMainButtonColor(isListening, canStart),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _getMainButtonColor(isListening, canStart).withOpacity(0.3),
              spreadRadius: isListening ? 6 : 2,
              blurRadius: isListening ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isListening ? Icons.stop : Icons.mic,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            elevation: onPressed != null ? 3 : 1,
          ),
          child: Icon(icon, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: onPressed != null ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getMainButtonColor(bool isListening, bool canStart) {
    if (isListening) {
      return Colors.red;
    } else if (canStart) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  String _getStatusMessage(
    SpeechRecognitionState speechState,
    VerseTrackingState verseState,
  ) {
    if (verseState is VerseTrackingLoaded && verseState.isCompleted) {
      return '🎉 مبروك! لقد أكملت سورة الفاتحة';
    }
    
    if (speechState is SpeechRecognitionListening) {
      return 'جاري الاستماع... تحدث الآن لتلاوة الآية';
    } else if (speechState is SpeechRecognitionConnecting) {
      return 'جاري الاتصال بخادم التعرف على الصوت...';
    } else if (speechState is SpeechRecognitionDisconnected || 
               speechState is SpeechRecognitionError) {
      return 'غير متصل - اضغط "اتصال" للمحاولة مرة أخرى';
    } else if (speechState is SpeechRecognitionConnected) {
      if (verseState is VerseTrackingLoaded) {
        return 'اضغط على زر الميكروفون لبدء تلاوة الآية ${verseState.currentVerseIndex + 1}';
      }
      return 'جاهز للبدء';
    } else if (speechState is SpeechRecognitionStopped) {
      return 'تم إيقاف التسجيل - يمكنك البدء مرة أخرى';
    }
    
    return 'تحقق من الاتصال وحاول مرة أخرى';
  }
}