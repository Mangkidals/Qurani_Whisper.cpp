import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  StreamController<Uint8List>? _audioChunkController;
  Timer? _chunkTimer;
  String? _currentRecordingPath;
  
  bool get isRecording => _isRecording;
  
  Stream<Uint8List> get audioChunkStream => 
      _audioChunkController?.stream ?? const Stream.empty();

  Future<bool> requestPermissions() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> startContinuousRecording() async {
    try {
      if (!await requestPermissions()) {
        print('Microphone permission denied');
        return false;
      }

      if (!await _recorder.hasPermission()) {
        print('Audio recorder permission denied');
        return false;
      }

      final directory = await getTemporaryDirectory();
      _currentRecordingPath = '${directory.path}/continuous_recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          bitRate: 16000,
          numChannels: 1,
        ),
        path: _currentRecordingPath!,
      );
      
      _isRecording = true;
      _audioChunkController = StreamController<Uint8List>.broadcast();
      
      // Start chunked audio processing
      _startChunkedProcessing();
      
      print('Continuous recording started');
      return true;
    } catch (e) {
      print('Error starting continuous recording: $e');
      return false;
    }
  }

  void _startChunkedProcessing() {
    // Process audio in chunks every 500ms for real-time transcription
    _chunkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      
      await _processCurrentAudioChunk();
    });
  }

  Future<void> _processCurrentAudioChunk() async {
    if (_currentRecordingPath == null) return;
    
    try {
      final file = File(_currentRecordingPath!);
      if (await file.exists()) {
        final audioBytes = await file.readAsBytes();
        
        // Only send if we have enough audio data (avoid sending tiny chunks)
        if (audioBytes.length > 1024) { // At least 1KB of audio
          _audioChunkController?.add(audioBytes);
        }
      }
    } catch (e) {
      print('Error processing audio chunk: $e');
    }
  }

  Future<Uint8List?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      _chunkTimer?.cancel();
      _chunkTimer = null;

      final path = await _recorder.stop();
      _isRecording = false;

      if (path != null && File(path).existsSync()) {
        final finalAudioBytes = await File(path).readAsBytes();
        
        // Send final chunk
        if (finalAudioBytes.isNotEmpty) {
          _audioChunkController?.add(finalAudioBytes);
        }
        
        // Clean up
        await File(path).delete();
        _audioChunkController?.close();
        _audioChunkController = null;
        
        print('Recording stopped, final file size: ${finalAudioBytes.length} bytes');
        return finalAudioBytes;
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
    
    _audioChunkController?.close();
    _audioChunkController = null;
    return null;
  }

  Future<void> dispose() async {
    _chunkTimer?.cancel();
    if (_isRecording) {
      await stopRecording();
    }
    await _recorder.dispose();
  }
}