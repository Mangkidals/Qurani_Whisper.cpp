import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/speech_recognition/speech_recognition_bloc.dart';

class ConnectionStatusCard extends StatelessWidget {
  const ConnectionStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SpeechRecognitionBloc, SpeechRecognitionState>(
      builder: (context, state) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getBackgroundColor(state),
            border: Border.all(color: _getBorderColor(state)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                _getIcon(state),
                color: _getIconColor(state),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTitle(state),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _getTextColor(state),
                      ),
                    ),
                    if (_getSubtitle(state) != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _getSubtitle(state)!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getTextColor(state).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (state is SpeechRecognitionListening)
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.circle,
                      color: Colors.red,
                      size: 8,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(SpeechRecognitionState state) {
    switch (state.runtimeType) {
      case SpeechRecognitionConnected:
      case SpeechRecognitionListening:
      case SpeechRecognitionStopped:
        return Colors.green.shade50;
      case SpeechRecognitionConnecting:
        return Colors.blue.shade50;
      case SpeechRecognitionError:
      case SpeechRecognitionDisconnected:
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getBorderColor(SpeechRecognitionState state) {
    switch (state.runtimeType) {
      case SpeechRecognitionConnected:
      case SpeechRecognitionListening:
      case SpeechRecognitionStopped:
        return Colors.green;
      case SpeechRecognitionConnecting:
        return Colors.blue;
      case SpeechRecognitionError:
      case SpeechRecognitionDisconnected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getIconColor(SpeechRecognitionState state) {
    return _getBorderColor(state);
  }

  Color _getTextColor(SpeechRecognitionState state) {
    switch (state.runtimeType) {
      case SpeechRecognitionConnected:
      case SpeechRecognitionListening:
      case SpeechRecognitionStopped:
        return Colors.green.shade700;
      case SpeechRecognitionConnecting:
        return Colors.blue.shade700;
      case SpeechRecognitionError:
      case SpeechRecognitionDisconnected:
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getIcon(SpeechRecognitionState state) {
    switch (state.runtimeType) {
      case SpeechRecognitionConnected:
        return Icons.wifi;
      case SpeechRecognitionListening:
        return Icons.mic;
      case SpeechRecognitionStopped:
        return Icons.check_circle;
      case SpeechRecognitionConnecting:
        return Icons.wifi_find;
      case SpeechRecognitionError:
        return Icons.error;
      case SpeechRecognitionDisconnected:
        return Icons.wifi_off;
      default:
        return Icons.help_outline;
    }
  }

  String _getTitle(SpeechRecognitionState state) {
    switch (state.runtimeType) {
      case SpeechRecognitionConnected:
        return 'متصل بخادم التعرف على الصوت';
      case SpeechRecognitionListening:
        return 'جاري الاستماع...';
      case SpeechRecognitionStopped:
        return 'تم إيقاف التسجيل';
      case SpeechRecognitionConnecting:
        return 'جاري الاتصال...';
      case SpeechRecognitionError:
        return 'خطأ في الاتصال';
      case SpeechRecognitionDisconnected:
        return 'غير متصل';
      default:
        return 'حالة غير معروفة';
    }
  }

  String? _getSubtitle(SpeechRecognitionState state) {
    switch (state.runtimeType) {
      case SpeechRecognitionConnected:
        return 'اضغط "بدء الاستماع" للتسجيل';
      case SpeechRecognitionListening:
        return 'تحدث الآن لتلاوة الآية';
      case SpeechRecognitionConnecting:
        return 'الرجاء الانتظار...';
      case SpeechRecognitionError:
        if (state is SpeechRecognitionError) {
          return state.error;
        }
        return 'حدث خطأ غير متوقع';
      case SpeechRecognitionDisconnected:
        if (state is SpeechRecognitionDisconnected && state.error != null) {
          return state.error;
        }
        return 'تحقق من اتصال الخادم';
      default:
        return null;
    }
  }
}