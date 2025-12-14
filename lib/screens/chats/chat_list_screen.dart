import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rentmate/constants.dart';
import 'dart:convert';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  final String currentUserId;

  const ChatListScreen({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<ChatPreview> chats = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    print('🔷 [ChatListScreen] ========== LOADING CHATS ==========');
    print('🔷 [ChatListScreen] User ID: ${widget.currentUserId}');
    print(
      '🔷 [ChatListScreen] API URL: ${kBaseUrl}/chat/user/${widget.currentUserId}',
    );

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Replace with your server URL
      final response = await http.get(
        Uri.parse(
          '${kBaseUrl}/chat/user/${widget.currentUserId}',
        ),
      );

      print('🔷 [ChatListScreen] Response status: ${response.statusCode}');
      print('🔷 [ChatListScreen] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        print('✅ [ChatListScreen] Found ${data.length} chats');
        if (mounted) {
          setState(() {
            chats = data.map((chat) => ChatPreview.fromJson(chat)).toList();
            isLoading = false;
          });
        }
      } else {
        print('❌ [ChatListScreen] Failed with status: ${response.statusCode}');
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to load chats';
            isLoading = false;
          });
        }
      }
    } catch (e, stackTrace) {
      print('❌ [ChatListScreen] Error loading chats: $e');
      print('❌ [ChatListScreen] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          errorMessage = 'Connection error. Please try again.';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteChat(String chatId) async {
    try {
      final response = await http.delete(
        Uri.parse('$kBaseUrl/chat/$chatId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          chats.removeWhere((chat) => chat.chatId == chatId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chat deleted')),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadChats,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(errorMessage!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChats,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No chats yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start renting items to chat with owners',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      child: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return _buildChatTile(chat);
        },
      ),
    );
  }

  Widget _buildChatTile(ChatPreview chat) {
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Delete Chat"),
              content: const Text("Are you sure you want to delete this chat?"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteChat(chat.chatId);
                  },
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              requestId: chat.requestId,
              currentUserId: widget.currentUserId,
              otherUserName: chat.otherUserName,
              itemName: chat.itemName,
              chatId: chat.chatId,
            ),
          ),
        ).then((_) => _loadChats()); // Refresh when returning
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12, left: 8, right: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue[50],
              child: Text(
                chat.otherUserName.isNotEmpty
                    ? chat.otherUserName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.otherUserName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(chat.lastMessageTime),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: chat.unreadCount > 0
                                ? Colors.black87
                                : Colors.grey[600],
                            fontWeight: chat.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            chat.unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}

class ChatPreview {
  final String chatId;
  final String requestId;
  final String otherUserName;
  final String itemName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  ChatPreview({
    required this.chatId,
    required this.requestId,
    required this.otherUserName,
    required this.itemName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory ChatPreview.fromJson(Map<String, dynamic> json) {
    // Safety checks for nested data
    final requestIdObj = json['requestId'];
    final participants = json['participants'] as List?;

    String reqId = '';
    String itemName = 'Unknown Item';
    String otherName = 'Unknown User';

    if (requestIdObj != null) {
      reqId = requestIdObj['_id'] ?? '';
      if (requestIdObj['itemId'] != null) {
        itemName = requestIdObj['itemId']['itemName'] ?? 'Unknown Item';
      }
    }

    if (participants != null && participants.isNotEmpty) {
      otherName = participants[0]['name'] ?? 'Unknown User';
    }

    return ChatPreview(
      chatId: json['_id'] ?? '',
      requestId: reqId,
      otherUserName: otherName,
      itemName: itemName,
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}
