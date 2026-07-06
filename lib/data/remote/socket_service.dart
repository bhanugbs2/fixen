import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/env/env_config.dart';

class SocketService {
  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void initialize(String token) {
    if (_socket != null) {
      log('Socket already initialized. Disconnecting first.');
      disconnect();
    }

    log('Initializing Socket connection to: ${EnvConfig.socketUrl}');
    _socket = io.io(
      EnvConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      log('Socket connected successfully');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      log('Socket disconnected');
    });

    _socket!.onConnectError((data) {
      log('Socket connection error: $data');
    });

    _socket!.connect();
  }

  void emit(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
    } else {
      log('Socket not connected. Cannot emit $event.');
    }
  }

  void on(String event, Function(dynamic data) handler) {
    if (_socket != null) {
      _socket!.on(event, handler);
    }
  }

  void off(String event) {
    if (_socket != null) {
      _socket!.off(event);
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
    }
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});
