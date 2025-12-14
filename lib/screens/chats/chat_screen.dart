import 'package:flutter/material.dart';
import 'package:rentmate/services/socket_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:rentmate/constants.dart';

class ChatScreen extends StatefulWidget {
  final String requestId;
  final String currentUserId;
  final String otherUserName;
  final String itemName;
  final String? chatId; // Optional

  const ChatScreen({
    required this.requestId,
    required this.currentUserId,
    required this.otherUserName,
    required this.itemName,
    this.chatId,
    Key? key,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final SocketService _socketService = SocketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Message> messages = [];
  bool isLoading = true;
  bool isSending = false;
  String? errorMessage;
  bool hasConnectionError = false;
  StreamSubscription? _connectionSubscription;
  bool isSelfChat = false;
  String? _currentChatId;

  @override
  void initState() {
    super.initState();
    _currentChatId = widget.chatId;
    _checkRequestDetails();
    _initializeChat();
    if (_currentChatId == null) {
      _fetchChatId();
    }
  }

  Future<void> _fetchChatId() async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/chat/request/${widget.requestId}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _currentChatId = data['_id'];
          });
        }
      }
    } catch (e) {
      print('Error fetching chatId: $e');
    }
  }

  Future<void> _deleteChat() async {
    if (_currentChatId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Chat'),
        content: Text('Are you sure you want to delete this chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('$kBaseUrl/chat/$_currentChatId'),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete chat')),
        );
      }
    } catch (e) {
      print('Error deleting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting chat')),
      );
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    if (_currentChatId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Message'),
        content: Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('$kBaseUrl/chat/$_currentChatId/messages/$messageId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          messages.removeWhere((m) => m.messageId == messageId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete message')),
        );
      }
    } catch (e) {
      print('Error deleting message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message')),
      );
    }
  }

  // ... existing code ...

  Future<void> _checkRequestDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/rent-request/${widget.requestId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final customerId = data['customerId'] is Map
            ? data['customerId']['_id']
            : data['customerId'];
        final renterId = data['renterId'] is Map
            ? data['renterId']['_id']
            : data['renterId'];

        // If the backend allows it (e.g. legacy data) or if someone bypassed checks,
        // we might find that customerId == renterId, OR we are chatting with ourselves
        // if both participants are the same user (unlikely unless self-rent),
        // OR simply if we want to flag it.
        // The most direct "self chat" check is:
        if (customerId.toString() == renterId.toString()) {
          setState(() => isSelfChat = true);
        }
      }
    } catch (e) {
      print('Error fetching request details: $e');
    }
  }

  void _initializeChat() {
    print('🔷 [ChatScreen] Initializing chat for request: ${widget.requestId}');

    // Connect to socket
    _socketService.connect();

    // Listen to connection status events
    _connectionSubscription = _socketService.connectionStatus.listen((
      isConnected,
    ) {
      if (!mounted) return;

      if (isConnected) {
        setState(() {
          hasConnectionError = false;
          errorMessage = null;
        });
        _socketService.joinChat(widget.requestId);
      } else {
        setState(() {
          hasConnectionError = true;
          errorMessage = 'Disconnected from server';
        });
      }
    });

    if (_socketService.isConnected) {
      _socketService.joinChat(widget.requestId);
    }

    _socketService.onChatHistory((data) {
      if (!mounted) return;
      try {
        List<Message> parsedMessages = [];
        if (data != null && data is List) {
          parsedMessages = data
              .map((msg) => Message.fromJson(msg as Map<String, dynamic>))
              .toList();
        }
        setState(() {
          messages = parsedMessages;
          isLoading = false;
        });
        _scrollToBottom();
      } catch (e) {
        print('❌ [ChatScreen] Error processing chat history: $e');
        setState(() => isLoading = false);
      }
    });

    _socketService.onReceiveMessage((data) {
      if (!mounted) return;
      try {
        final newMessage = Message.fromJson(data as Map<String, dynamic>);
        setState(() {
          messages.add(newMessage);
          isSending = false;
        });
        _scrollToBottom();
      } catch (e) {
        print('❌ [ChatScreen] Error parsing new message: $e');
      }
    });

    _socketService.onSocketError((error) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Socket error: ${error.toString()}';
        hasConnectionError = true;
      });
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _socketService.leaveChat(widget.requestId);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || isSending) return;

    if (!_socketService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not connected. Retrying...')),
      );
      _retryConnection();
      return;
    }

    setState(() => isSending = true);

    _socketService.sendMessage(
      widget.requestId,
      widget.currentUserId,
      _messageController.text.trim(),
    );

    _messageController.clear();
    _focusNode.requestFocus();
  }

  void _retryConnection() {
    setState(() {
      isLoading = true;
      hasConnectionError = false;
      errorMessage = null;
    });
    _socketService.reconnect();
    _initializeChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              radius: 18,
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: TextStyle(color: Colors.blue[800], fontSize: 14),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.itemName,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // if (_currentChatId != null)
          //   IconButton(
          //     icon: Icon(Icons.delete_outline, color: Colors.red),
          //     onPressed: _deleteChat,
          //   ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _socketService.isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (isSelfChat)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.amber[100],
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Colors.amber[900]),
                  SizedBox(width: 8),
                  Text(
                    'You are verifying the chat feature (Self-Chat)',
                    style: TextStyle(color: Colors.amber[900], fontSize: 13),
                  ),
                ],
              ),
            ),
          if (hasConnectionError && errorMessage != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              color: Colors.red[100],
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[900]),
              ),
            ),
          Expanded(child: _buildMessagesList()),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text('No messages yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == widget.currentUserId;

        // Show date if needed
        bool showDate = false;
        if (index == 0) {
          showDate = true;
        } else {
          final prevDate = messages[index - 1].timestamp;
          final currDate = message.timestamp;
          if (prevDate.day != currDate.day ||
              prevDate.month != currDate.month ||
              prevDate.year != currDate.year) {
            showDate = true;
          }
        }

        return GestureDetector(
          onLongPress: () {
            if (isMe) {
              _deleteMessage(message.messageId);
            }
          },
          child: Column(
            children: [
              if (showDate) _buildDateDivider(message.timestamp),
              Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: EdgeInsets.only(
                    bottom: 8,
                    left: isMe ? 50 : 0,
                    right: isMe ? 0 : 50,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: isMe
                          ? Radius.circular(20)
                          : Radius.circular(4),
                      bottomRight: isMe
                          ? Radius.circular(4)
                          : Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white54 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${date.day}/${date.month}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -2),
            blurRadius: 10,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: isSending
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class Message {
  final String messageId;
  final String senderId;
  final String text;
  final DateTime timestamp;

  Message({
    this.messageId = '',
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['_id'] ?? '',
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
