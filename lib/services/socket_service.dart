import 'package:rentmate/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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

  void connect() {
    if (socket != null && _isConnected) {
      print('Socket already connected');
      return;
    }

    try {
      socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket']) // Use WebSocket only
            .disableAutoConnect() // Manual connection
            .setTimeout(5000) // Connection timeout
            .setReconnectionDelay(1000) // Reconnect after 1 second
            .setReconnectionAttempts(5) // Try 5 times
            .build(),
      );

      socket!.connect();

      // Connection events
      socket!.onConnect((_) {
        _isConnected = true;
        print('✅ Connected to socket server');
      });

      socket!.onConnectError((error) {
        _isConnected = false;
        print('❌ Connection error: $error');
      });

      socket!.onConnectTimeout((data) {
        _isConnected = false;
        print('⏱️ Connection timeout');
      });

      socket!.onDisconnect((_) {
        _isConnected = false;
        print('🔌 Disconnected from socket server');
      });

      socket!.onReconnect((data) {
        _isConnected = true;
        print('🔄 Reconnected to socket server');
      });

      socket!.onReconnectError((error) {
        print('❌ Reconnection error: $error');
      });

      socket!.onReconnectFailed((_) {
        _isConnected = false;
        print('❌ Reconnection failed');
      });

      socket!.onError((error) {
        print('❌ Socket error: $error');
      });
    } catch (e) {
      print('❌ Error initializing socket: $e');
    }
  }

  void disconnect() {
    if (socket != null) {
      socket!.disconnect();
      socket!.dispose();
      socket = null;
      _isConnected = false;
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
