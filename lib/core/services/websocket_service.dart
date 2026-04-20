// lib/core/services/websocket_service.dart
//
// Base WebSocket service. All feature-specific WS services
// extend this class and override wsUrl + subscribePayload.
//
// Usage example (in trading):
//   class NewsWebSocketService extends BaseWebSocketService {
//     @override
//     String get wsUrl => 'wss://your-provider.com/ws';
//     @override
//     Map<String, dynamic>? get subscribePayload => {'action': 'subscribe'};
//   }

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import '../constants/app_constants.dart';

typedef WsMessageCallback = void Function(Map<String, dynamic> data);
typedef WsErrorCallback   = void Function(Object error);
typedef WsStateCallback   = void Function(WsConnectionState state);

enum WsConnectionState {
  connecting,
  connected,
  disconnected,
  reconnecting,
  failed,
}

abstract class BaseWebSocketService {
  WebSocketChannel?   _channel;
  StreamSubscription? _subscription;
  Timer?              _reconnectTimer;
  Timer?              _heartbeatTimer;

  bool _shouldReconnect = false;
  int  _retryCount      = 0;

  WsConnectionState _state = WsConnectionState.disconnected;

  // ── Overridables ──────────────────────────────────────────────────────────

  /// WebSocket endpoint — must override
  String get wsUrl;

  /// Optional subscription payload sent on connect
  Map<String, dynamic>? get subscribePayload => null;

  /// Heartbeat interval — override to change
  Duration get heartbeatInterval => const Duration(seconds: 30);

  int      get maxRetries     => AppConstants.wsMaxRetries;
  Duration get reconnectDelay =>
      Duration(seconds: AppConstants.wsReconnectDelaySeconds);

  // ── Callbacks — set before calling connect() ──────────────────────────────

  WsMessageCallback? onMessage;
  WsErrorCallback?   onError;
  WsStateCallback?   onStateChange;

  // ── Public API ────────────────────────────────────────────────────────────

  WsConnectionState get connectionState => _state;
  bool get isConnected => _state == WsConnectionState.connected;

  Future<void> connect() async {
    if (isConnected) return;
    _shouldReconnect = true;
    _retryCount      = 0;
    _tryConnect();
  }

  void send(Map<String, dynamic> payload) {
    if (!isConnected) return;
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (_) {}
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close(ws_status.goingAway);
    _setState(WsConnectionState.disconnected);
  }

  void dispose() => disconnect();

  // ── Internal ──────────────────────────────────────────────────────────────

  void _tryConnect() {
    _setState(WsConnectionState.connecting);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _setState(WsConnectionState.connected);
      _retryCount = 0;

      if (subscribePayload != null) {
        _channel!.sink.add(jsonEncode(subscribePayload));
      }

      _subscription = _channel!.stream.listen(
        _onRawData,
        onError: _onStreamError,
        onDone:  _onStreamDone,
      );

      _startHeartbeat();
    } catch (e) {
      _setState(WsConnectionState.disconnected);
      onError?.call(e);
      _scheduleReconnect();
    }
  }

  void _onRawData(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      onMessage?.call(data);
    } catch (_) {
      // Malformed payload — ignore
    }
  }

  void _onStreamError(Object error) {
    _setState(WsConnectionState.disconnected);
    onError?.call(error);
    _scheduleReconnect();
  }

  void _onStreamDone() {
    _setState(WsConnectionState.disconnected);
    if (_shouldReconnect) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect || _retryCount >= maxRetries) {
      _setState(WsConnectionState.failed);
      return;
    }
    _setState(WsConnectionState.reconnecting);
    _retryCount++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(reconnectDelay, _tryConnect);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      if (isConnected) {
        try {
          _channel?.sink.add(jsonEncode({'type': 'ping'}));
        } catch (_) {}
      }
    });
  }

  void _setState(WsConnectionState newState) {
    if (_state == newState) return;
    _state = newState;
    onStateChange?.call(newState);
  }
}
