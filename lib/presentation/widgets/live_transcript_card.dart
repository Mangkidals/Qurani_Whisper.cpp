import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/speech_recognition/speech_recognition_bloc.dart';

class LiveTranscriptCard extends StatelessWidget {
  const LiveTranscriptCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpeechRecognitionBloc, SpeechRecognitionState>(
      builder: (context, state) {
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.transcribe,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'النص المتعرف عليه مباشرة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (state is SpeechRecognitionListening)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Transcript content
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getBackgroundColor(state),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getBorderColor(state),
                        width: 1.5,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_getTranscriptText(state).isNotEmpty) ...[
                            Text(
                              _getTranscriptText(state),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                height: 1.6,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ] else ...[
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getPlaceholderIcon(state),
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _getPlaceholderText(state),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Status indicator
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(state),
                      size: 16,
                      color: _getStatusColor(state),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusText(state),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(state),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(SpeechRecognitionState state) {
    if (state is SpeechRecognitionListening) {
      return Colors.green.shade50;
    } else if (state is SpeechRecognitionStopped && 
               _getTranscriptText(state).isNotEmpty) {
      return Colors.blue.shade50;
    }
    return Colors.grey.shade50;
  }

  Color _getBorderColor(SpeechRecognitionState state) {
    if (state is SpeechRecognitionListening) {
      return Colors.green.shade200;
    } else if (state is SpeechRecognitionStopped && 
               _getTranscriptText(state).isNotEmpty) {
      return Colors.blue.shade200;
    }
    return Colors.grey.shade300;
  }

  String _getTranscriptText(SpeechRecognitionState state) {
    if (state is SpeechRecognitionListening) {
      return state.liveTranscript;
    } else if (state is SpeechRecognitionStopped) {
      return state.finalTranscript;
    }
    return '';
  }

  IconData _getPlaceholderIcon(SpeechRecognitionState state) {
    if (state is SpeechRecognitionConnected) {
      return Icons.mic_none;
    } else if (state is SpeechRecognitionDisconnected || 
               state is SpeechRecognitionError) {
      return Icons.wifi_off;
    } else if (state is SpeechRecognitionConnecting) {
      return Icons.hourglass_empty;
    }
    return Icons.text_fields;
  }

  String _getPlaceholderText(SpeechRecognitionState state) {
    if (state is SpeechRecognitionConnected) {
      return 'اضغط "بدء الاستماع" لرؤية النص المتعرف عليه هنا';
    } else if (state is SpeechRecognitionListening) {
      return 'جاري الاستماع... تحدث الآن';
    } else if (state is SpeechRecognitionDisconnected || 
               state is SpeechRecognitionError) {
      return 'غير متصل بخادم التعرف على الصوت';
    } else if (state is SpeechRecognitionConnecting) {
      return 'جاري الاتصال بالخادم...';
    }
    return 'لا يوجد نص متاح';
  }

  IconData _getStatusIcon(SpeechRecognitionState state) {
    if (state is SpeechRecognitionListening) {
      return Icons.radio_button_checked;
    } else if (state is SpeechRecognitionStopped) {
      return Icons.check_circle_outline;
    } else if (state is SpeechRecognitionConnected) {
      return Icons.wifi;
    } else if (state is SpeechRecognitionError) {
      return Icons.error_outline;
    }
    return Icons.circle_outlined;
  }

  Color _getStatusColor(SpeechRecognitionState state) {
    if (state is SpeechRecognitionListening) {
      return Colors.green;
    } else if (state is SpeechRecognitionStopped) {
      return Colors.blue;
    } else if (state is SpeechRecognitionConnected) {
      return Colors.green;
    } else if (state is SpeechRecognitionError) {
      return Colors.red;
    }
    return Colors.grey;
  }

  String _getStatusText(SpeechRecognitionState state) {
    if (state is SpeechRecognitionListening) {
      return 'جاري التسجيل والتعرف...';
    } else if (state is SpeechRecognitionStopped) {
      return 'تم إيقاف التسجيل';
    } else if (state is SpeechRecognitionConnected) {
      return 'جاهز للتسجيل';
    } else if (state is SpeechRecognitionError) {
      return 'حدث خطأ';
    } else if (state is SpeechRecognitionDisconnected) {
      return 'غير متصل';
    } else if (state is SpeechRecognitionConnecting) {
      return 'جاري الاتصال...';
    }
    return 'غير معروف';
  }
}