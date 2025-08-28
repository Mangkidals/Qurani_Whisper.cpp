import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class VoskService {
  static const String _host = 'localhost';
  static const int _port = 2700;
  
  WebSocketChannel? _channel;
  bool _isConnected = false;
  StreamController<String>? _transcriptController;
  
  bool get isConnected => _isConnected;
  
  Stream<String> get transcriptStream => 
      _transcriptController?.stream ?? const Stream.empty();
  
  Future<bool> connect() async {
    try {
      final uri = Uri.parse('ws://$_host:$_port');
      _channel = WebSocketChannel.connect(uri);
      
      await _channel!.ready;
      _isConnected = true;
      
      _transcriptController = StreamController<String>.broadcast();
      
      // Listen to WebSocket messages
      _channel!.stream.listen(
        (data) {
          try {
            final result = json.decode(data);
            
            // Handle both partial and final results
            if (result['partial'] != null && result['partial'].toString().isNotEmpty) {
              _transcriptController?.add(result['partial'].toString());
            } else if (result['text'] != null && result['text'].toString().isNotEmpty) {
              _transcriptController?.add(result['text'].toString());
            }
          } catch (e) {
            print('Error parsing Vosk response: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleDisconnection();
        },
      );
      
      print('Connected to Vosk server at $_host:$_port');
      return true;
    } catch (e) {
      print('Failed to connect to Vosk server: $e');
      _isConnected = false;
      return false;
    }
  }
  
  void _handleDisconnection() {
    _isConnected = false;
    _transcriptController?.close();
    _transcriptController = null;
  }
  
  Future<void> sendAudioData(Uint8List audioData) async {
    if (!_isConnected || _channel == null) {
      print('Not connected to Vosk server');
      return;
    }
    
    try {
      _channel!.sink.add(audioData);
    } catch (e) {
      print('Error sending audio data: $e');
      _handleDisconnection();
    }
  }
  
  Future<void> sendAudioChunk(List<int> audioChunk) async {
    if (!_isConnected || _channel == null) return;
    
    try {
      _channel!.sink.add(Uint8List.fromList(audioChunk));
    } catch (e) {
      print('Error sending audio chunk: $e');
      _handleDisconnection();
    }
  }
  
  Future<void> finalize() async {
    if (!_isConnected || _channel == null) return;
    
    try {
      _channel!.sink.add(json.encode({"eof": 1}));
    } catch (e) {
      print('Error finalizing: $e');
    }
  }
  
  Future<void> disconnect() async {
    if (_channel != null) {
      try {
        await _channel!.sink.close(status.goingAway);
      } catch (e) {
        print('Error closing WebSocket: $e');
      }
    }
    
    _handleDisconnection();
    _channel = null;
    print('Disconnected from Vosk server');
  }
  
  Future<void> dispose() async {
    await disconnect();
  }
}