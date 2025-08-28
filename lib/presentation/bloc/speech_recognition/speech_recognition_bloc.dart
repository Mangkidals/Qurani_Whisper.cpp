import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/services/audio_service.dart';
import '../../../data/services/vosk_service.dart';

// Events
abstract class SpeechRecognitionEvent extends Equatable {
  const SpeechRecognitionEvent();

  @override
  List<Object> get props => [];
}

class ConnectToSTT extends SpeechRecognitionEvent {}

class StartListening extends SpeechRecognitionEvent {}

class StopListening extends SpeechRecognitionEvent {}

class DisconnectFromSTT extends SpeechRecognitionEvent {}

class _TranscriptReceived extends SpeechRecognitionEvent {
  final String transcript;

  const _TranscriptReceived(this.transcript);

  @override
  List<Object> get props => [transcript];
}

class _AudioChunkReceived extends SpeechRecognitionEvent {
  final List<int> audioData;

  const _AudioChunkReceived(this.audioData);

  @override
  List<Object> get props => [audioData];
}

// States
abstract class SpeechRecognitionState extends Equatable {
  const SpeechRecognitionState();

  @override
  List<Object> get props => [];
}

class SpeechRecognitionInitial extends SpeechRecognitionState {}

class SpeechRecognitionConnecting extends SpeechRecognitionState {}

class SpeechRecognitionConnected extends SpeechRecognitionState {}

class SpeechRecognitionDisconnected extends SpeechRecognitionState {
  final String? error;

  const SpeechRecognitionDisconnected({this.error});

  @override
  List<Object> get props => [error ?? ''];
}

class SpeechRecognitionListening extends SpeechRecognitionState {
  final String liveTranscript;

  const SpeechRecognitionListening({this.liveTranscript = ''});

  @override
  List<Object> get props => [liveTranscript];
}

class SpeechRecognitionStopped extends SpeechRecognitionState {
  final String finalTranscript;

  const SpeechRecognitionStopped({this.finalTranscript = ''});

  @override
  List<Object> get props => [finalTranscript];
}

class SpeechRecognitionError extends SpeechRecognitionState {
  final String error;

  const SpeechRecognitionError(this.error);

  @override
  List<Object> get props => [error];
}

// BLoC
class SpeechRecognitionBloc extends Bloc<SpeechRecognitionEvent, SpeechRecognitionState> {
  final VoskService voskService;
  final AudioService audioService;

  StreamSubscription<String>? _transcriptSubscription;
  StreamSubscription<List<int>>? _audioSubscription;
  String _currentTranscript = '';

  SpeechRecognitionBloc({
    required this.voskService,
    required this.audioService,
  }) : super(SpeechRecognitionInitial()) {
    on<ConnectToSTT>(_onConnectToSTT);
    on<StartListening>(_onStartListening);
    on<StopListening>(_onStopListening);
    on<DisconnectFromSTT>(_onDisconnectFromSTT);
    on<_TranscriptReceived>(_onTranscriptReceived);
    on<_AudioChunkReceived>(_onAudioChunkReceived);
  }

  Future<void> _onConnectToSTT(
    ConnectToSTT event,
    Emitter<SpeechRecognitionState> emit,
  ) async {
    emit(SpeechRecognitionConnecting());

    try {
      final connected = await voskService.connect();
      
      if (connected) {
        // Listen to transcript stream
        _transcriptSubscription = voskService.transcriptStream.listen(
          (transcript) => add(_TranscriptReceived(transcript)),
        );
        
        emit(SpeechRecognitionConnected());
      } else {
        emit(const SpeechRecognitionDisconnected(
          error: 'Failed to connect to STT server',
        ));
      }
    } catch (e) {
      emit(SpeechRecognitionDisconnected(error: e.toString()));
    }
  }

  Future<void> _onStartListening(
    StartListening event,
    Emitter<SpeechRecognitionState> emit,
  ) async {
    if (state is! SpeechRecognitionConnected && 
        state is! SpeechRecognitionStopped) {
      return;
    }

    try {
      _currentTranscript = '';
      
      // Start continuous audio recording
      final started = await audioService.startContinuousRecording();
      
      if (started) {
        // Listen to audio chunks and forward to STT
        _audioSubscription = audioService.audioChunkStream.listen(
          (audioData) => add(_AudioChunkReceived(audioData)),
        );
        
        emit(const SpeechRecognitionListening());
      } else {
        emit(const SpeechRecognitionError('Failed to start audio recording'));
      }
    } catch (e) {
      emit(SpeechRecognitionError(e.toString()));
    }
  }

  Future<void> _onStopListening(
    StopListening event,
    Emitter<SpeechRecognitionState> emit,
  ) async {
    if (state is! SpeechRecognitionListening) return;

    try {
      // Stop audio recording and get final audio data
      await audioService.stopRecording();
      
      // Cancel audio subscription
      await _audioSubscription?.cancel();
      _audioSubscription = null;
      
      // Send finalization signal to STT
      await voskService.finalize();
      
      emit(SpeechRecognitionStopped(finalTranscript: _currentTranscript));
    } catch (e) {
      emit(SpeechRecognitionError(e.toString()));
    }
  }

  Future<void> _onDisconnectFromSTT(
    DisconnectFromSTT event,
    Emitter<SpeechRecognitionState> emit,
  ) async {
    await _cleanupSubscriptions();
    await voskService.disconnect();
    emit(const SpeechRecognitionDisconnected());
  }

  void _onTranscriptReceived(
    _TranscriptReceived event,
    Emitter<SpeechRecognitionState> emit,
  ) {
    _currentTranscript = event.transcript;
    
    if (state is SpeechRecognitionListening) {
      emit(SpeechRecognitionListening(liveTranscript: _currentTranscript));
    }
  }

  Future<void> _onAudioChunkReceived(
    _AudioChunkReceived event,
    Emitter<SpeechRecognitionState> emit,
  ) async {
    // Forward audio chunk to STT service
    await voskService.sendAudioChunk(event.audioData);
  }

  Future<void> _cleanupSubscriptions() async {
    await _transcriptSubscription?.cancel();
    await _audioSubscription?.cancel();
    _transcriptSubscription = null;
    _audioSubscription = null;
  }

  @override
  Future<void> close() async {
    await _cleanupSubscriptions();
    await audioService.dispose();
    await voskService.dispose();
    await super.close();
  }
}