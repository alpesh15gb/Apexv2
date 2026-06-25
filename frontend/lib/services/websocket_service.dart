import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../core/constants.dart';
import '../core/secure_storage.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  bool _isConnecting = false;
  Timer? _reconnectTimer;
  int _failCount = 0;
  static const int _maxFailures = 3;

  Stream<Map<String, dynamic>> get stream => _messageController.stream;

  Future<void> connect() async {
    if (_channel != null || _isConnecting) return;
    if (_failCount >= _maxFailures) return; // Stop retrying after max failures

    _isConnecting = true;

    final token = await secureStorage.read(StorageKeys.accessToken);
    if (token == null || token.isEmpty) {
      _isConnecting = false;
      return;
    }

    final wsUrl = ApiConstants.wsUrl;
    final wsUri = Uri.parse('$wsUrl?token=$token');

    try {
      _channel = WebSocketChannel.connect(wsUri);
      _isConnecting = false;
      _failCount = 0;

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message.toString()) as Map<String, dynamic>;
            _messageController.add(data);
          } catch (e) {
            // ignore malformed message
          }
        },
        onError: (err) {
          _cleanup();
          _scheduleReconnect();
        },
        onDone: () {
          _cleanup();
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _isConnecting = false;
      _failCount++;
      _cleanup();
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_failCount >= _maxFailures) return; // Stop retrying
    _reconnectTimer = Timer(const Duration(seconds: 30), () {
      connect();
    });
  }

  void _cleanup() {
    _channel = null;
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _failCount = _maxFailures; // Prevent reconnection after explicit disconnect
    if (_channel != null) {
      _channel!.sink.close(status.goingAway);
      _cleanup();
    }
  }

  void send(String message) {
    _channel?.sink.add(message);
  }

  void ping() {
    send('ping');
  }
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() {
    service.disconnect();
  });
  return service;
});
