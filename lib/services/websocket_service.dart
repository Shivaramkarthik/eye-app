import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/config/backend_config.dart';
import '../data/remote/api_client.dart';
import 'database_service.dart';

enum WebSocketConnectionState {
  disconnected,
  reconnecting,
  authenticating,
  recoveringEvents,
  connected,
}

class WebSocketService {
  static final WebSocketService instance = WebSocketService._internal();
  WebSocketService._internal();

  WebSocket? _webSocket;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;

  WebSocketConnectionState _state = WebSocketConnectionState.disconnected;
  WebSocketConnectionState get state => _state;

  final _stateController = StreamController<WebSocketConnectionState>.broadcast();
  Stream<WebSocketConnectionState> get stateStream => _stateController.stream;

  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;

  String? _userId;
  String? _lastEventId;

  void initialize(String userId) {
    _userId = userId;
    connect();
  }

  void connect() async {
    if (_userId == null) return;
    _updateState(WebSocketConnectionState.reconnecting);

    try {
      final token = await ApiClient.instance.secureStorage.read(key: 'jwt_access_token') ?? '';
      final wsUrl = BackendConfig.baseUrl
          .replaceAll('http://', 'ws://')
          .replaceAll('https://', 'wss://')
          .replaceAll('/api/v1', '/api/v1/ws/$_userId?token=$token');

      _updateState(WebSocketConnectionState.authenticating);
      _webSocket = await WebSocket.connect(wsUrl);

      final authPayload = jsonEncode({
        'action': 'authenticate',
        'user_id': _userId,
        'token': token,
        'last_event_id': _lastEventId,
      });
      _webSocket?.add(authPayload);

      _subscription = _webSocket?.listen(
        (message) {
          _onMessageReceived(message);
        },
        onError: (error) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
      );
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _onMessageReceived(dynamic rawMessage) async {
    try {
      final data = jsonDecode(rawMessage.toString()) as Map<String, dynamic>;
      final eventType = data['event'] as String?;
      _lastEventId = data['event_id'] as String? ?? _lastEventId;

      if (eventType == 'authenticated') {
        _updateState(WebSocketConnectionState.recoveringEvents);
        _recoverMissedEvents();
        return;
      }

      _eventController.add(data);
      await _processRealtimeEvent(eventType, data['payload']);
    } catch (_) {}
  }

  Future<void> _recoverMissedEvents() async {
    if (_webSocket != null && _userId != null) {
      _webSocket?.add(jsonEncode({
        'action': 'recover_events',
        'user_id': _userId,
        'since': _lastEventId,
      }));
    }
    _updateState(WebSocketConnectionState.connected);
  }

  Future<void> _processRealtimeEvent(String? eventType, dynamic payload) async {
    if (eventType == null || payload == null) return;
    final map = payload is Map<String, dynamic> ? payload : <String, dynamic>{};

    switch (eventType) {
      case 'profile.created':
      case 'profile.updated':
        break;

      case 'prescription.created':
      case 'prescription.updated':
        break;

      case 'medication.created':
      case 'medication.updated':
        break;

      case 'score.updated':
        break;

      case 'subscription.updated':
        if (_userId != null && map['plan'] != null) {
          await DatabaseService.instance.updateUserPlan(
            _userId!,
            map['plan'],
            map['status'] ?? 'active',
            map['subscription_id'],
            map['expires_at'],
          );
        }
        break;

      default:
        break;
    }
  }

  void _handleDisconnect() {
    _subscription?.cancel();
    _subscription = null;
    _webSocket = null;
    _updateState(WebSocketConnectionState.disconnected);

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_state == WebSocketConnectionState.disconnected) {
        connect();
      }
    });
  }

  void _updateState(WebSocketConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _webSocket?.close();
    _stateController.close();
    _eventController.close();
  }
}
