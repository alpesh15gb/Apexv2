import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/secure_storage.dart';

class WebSocketService {
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get stream => _messageController.stream;

  // WebSocket disabled — backend endpoint not implemented
  // All data comes from REST APIs
  Future<void> connect() async {}

  void disconnect() {}

  void send(String message) {}

  void ping() {}
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});
