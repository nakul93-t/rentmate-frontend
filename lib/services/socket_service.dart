import 'package:rentmate/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class SocketService {
  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;
  bool _isConnected = false;

  // Replace with your server URL
  // For Android emulator: use 10.0.2.2
  // For physical device: use your computer's IP (e.g., 192.168.1.100)
  final String serverUrl = kIpAddress;

  bool get isConnected => _isConnected;

  // Connection status stream
  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  void connect() {
    print('🔷 [SocketService] ========== CONNECT ATTEMPT ==========');
    print('🔷 [SocketService] Server URL: $serverUrl');
    print(
      '🔷 [SocketService] Current state - socket exists: ${socket != null}, connected: $_isConnected',
    );

    if (socket != null && _isConnected) {
      print('🔷 [SocketService] Already connected, skipping');
      return;
    }

    // If socket exists but not connected, dispose and recreate
    if (socket != null && !_isConnected) {
      print('🔷 [SocketService] Disposing stale socket...');
      socket!.dispose();
      socket = null;
    }

    try {
      print('🔷 [SocketService] Using transports: [polling, websocket]');
      print('🔷 [SocketService] socket_io_client version: 3.x/4.x (EIO=4)');

      // Configuration for socket_io_client v3+
      socket = IO.io(
        serverUrl,
        <String, dynamic>{
          'transports': ['websocket'], // FORCE websocket only
          'autoConnect': false,
          'forceNew': true,
          'reconnection': true,
          'reconnectionAttempts': 100,
          'reconnectionDelay': 1000,
        },
      );

      print('🔷 [SocketService] Socket created with simplified config');
      print('🔷 [SocketService] Options: ${socket?.io.options}');
      print('🔷 [SocketService] Initiating connection...');
      socket!.connect();

      // Connection events
      socket!.onConnect((_) {
        _isConnected = true;
        _connectionStatusController.add(true);
        print('✅ [SocketService] ========== CONNECTED ==========');
        print('✅ [SocketService] Socket ID: ${socket!.id}');
        print('✅ [SocketService] Connected to: $serverUrl');
      });

      socket!.onConnectError((error) {
        _isConnected = false;
        _connectionStatusController.add(false);
        print('❌ [SocketService] ========== CONNECTION ERROR ==========');
        print('❌ [SocketService] Error: $error');
        print('❌ [SocketService] Error type: ${error.runtimeType}');
      });

      // Timeout event deprecated in v3/v4 of some clients, relies on connect_error

      socket!.onDisconnect((reason) {
        _isConnected = false;
        _connectionStatusController.add(false);
        print('🔌 [SocketService] ========== DISCONNECTED ==========');
        print('🔌 [SocketService] Reason: $reason');
      });

      socket!.onReconnect((data) {
        _isConnected = true;
        print('🔄 [SocketService] ========== RECONNECTED ==========');
        print('🔄 [SocketService] Attempt: $data');
      });

      socket!.onReconnectAttempt((attempt) {
        print('🔄 [SocketService] Reconnection attempt: $attempt');
      });

      socket!.onReconnectError((error) {
        print('❌ [SocketService] Reconnection error: $error');
      });

      socket!.onReconnectFailed((_) {
        _isConnected = false;
        _connectionStatusController.add(false);
        print('❌ [SocketService] ========== RECONNECTION FAILED ==========');
        print('❌ [SocketService] All reconnection attempts exhausted');
      });

      socket!.onError((error) {
        print('❌ [SocketService] Socket error: $error');
      });

      socket!.onPing((_) {
        print('📡 [SocketService] Ping sent');
      });

      socket!.onPong((_) {
        print('📡 [SocketService] Pong received');
      });

      // Add ANY event listener to see all events
      socket!.onAny((event, data) {
        print('🔔 [SocketService] Event received: $event');
        print('🔔 [SocketService] Data: $data');
      });

      print('🔷 [SocketService] All event listeners attached');
    } catch (e, stackTrace) {
      print('❌ [SocketService] Exception during connection: $e');
      print('❌ [SocketService] Stack trace: $stackTrace');
    }
  }

  void disconnect() {
    if (socket != null) {
      socket!.disconnect();
      socket!.dispose();
      socket = null;
      socket = null;
      _isConnected = false;
      _connectionStatusController.add(false);
      print('Socket disconnected and disposed');
    }
  }

  void reconnect() {
    disconnect();
    connect();
  }

  // Join a chat room
  void joinChat(String requestId) {
    if (socket != null && _isConnected) {
      socket!.emit('join_chat', requestId);
      print('📨 Joined chat room: $requestId');
    } else {
      print('❌ Cannot join chat - socket not connected');
    }
  }

  // Leave a chat room
  void leaveChat(String requestId) {
    if (socket != null && _isConnected) {
      socket!.emit('leave_chat', requestId);
      print('👋 Left chat room: $requestId');
    }
  }

  // Send a message
  void sendMessage(String requestId, String senderId, String text) {
    if (socket != null && _isConnected) {
      socket!.emit('send_message', {
        'requestId': requestId,
        'senderId': senderId,
        'text': text,
      });
      print('✉️ Message sent to room: $requestId');
    } else {
      print('❌ Cannot send message - socket not connected');
    }
  }

  // Listen for new messages
  void onReceiveMessage(Function(dynamic) callback) {
    if (socket != null) {
      socket!.on('receive_message', callback);
    }
  }

  // Listen for chat history
  void onChatHistory(Function(dynamic) callback) {
    if (socket != null) {
      socket!.on('chat_history', callback);
    }
  }

  // Listen for errors
  void onSocketError(Function(dynamic) callback) {
    if (socket != null) {
      socket!.on('error', callback);
    }
  }

  // Remove all listeners
  void removeAllListeners() {
    if (socket != null) {
      socket!.off('receive_message');
      socket!.off('chat_history');
      socket!.off('error');
      print('All listeners removed');
    }
  }

  // Check connection status
  void checkConnection() {
    if (socket != null) {
      print('Socket connected: $_isConnected');
      print('Socket instance exists: ${socket != null}');
    } else {
      print('Socket instance is null');
    }
  }
}
