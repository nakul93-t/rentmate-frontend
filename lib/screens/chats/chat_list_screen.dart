import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rentmate/constants.dart';
import 'package:rentmate/theme/app_colors.dart';
import 'package:rentmate/widgets/ui_components.dart';
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
  List<ChatPreview> filteredChats = [];
  bool isLoading = true;
  String? errorMessage;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChats();
    _searchController.addListener(_filterChats);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterChats() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredChats = List.from(chats);
      } else {
        filteredChats = chats.where((chat) {
          return chat.otherUserName.toLowerCase().contains(query) ||
              chat.lastMessage.toLowerCase().contains(query);
        }).toList();
      }
    });
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
            filteredChats = List.from(chats);
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
          filteredChats.removeWhere((chat) => chat.chatId == chatId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat deleted'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete chat'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error deleting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting chat'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with glass effect - matching home page style
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.white.withOpacity(0.7),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chats',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: _loadChats,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.refresh_rounded,
                            color: AppColors.primaryTeal,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Search Bar - matching home page pill style
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PillSearchBar(
                controller: _searchController,
                onChanged: (_) {}, // Already handled by listener
                hintText: 'Search contacts, chats...',
                onClear: () {
                  _searchController.clear();
                },
              ),
            ),
            // Chat List
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadChats,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredChats.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _searchController.text.isNotEmpty
                    ? 'No chats found'
                    : 'No chats yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isNotEmpty
                    ? 'Try a different search term'
                    : 'Start renting items to chat with owners',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      color: AppColors.primaryTeal,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredChats.length,
        itemBuilder: (context, index) {
          final chat = filteredChats[index];
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text("Delete Chat"),
              content: const Text("Are you sure you want to delete this chat?"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteChat(chat.chatId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Delete"),
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
              otherUserProfileImage: chat.otherUserProfileImage,
              itemName: chat.itemName,
              chatId: chat.chatId,
              itemId: chat.itemId,
            ),
          ),
        ).then((_) => _loadChats());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Item image with status indicator
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                children: [
                  // Item image or fallback icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: chat.itemImage != null
                        ? Image.network(
                            chat.itemImage!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Center(
                                  child: Icon(
                                    Icons.inventory_2_rounded,
                                    color: AppColors.primaryTeal,
                                    size: 28,
                                  ),
                                ),
                          )
                        : Center(
                            child: Icon(
                              Icons.inventory_2_rounded,
                              color: AppColors.primaryTeal,
                              size: 28,
                            ),
                          ),
                  ),
                  // Status dot
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(chat.status),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // Chat details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Item name + time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.itemName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(chat.lastMessageTime),
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Row 2: User name + status badge
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          chat.otherUserName,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(chat.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Row 3: Last message + unread count
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage.isNotEmpty
                              ? chat.lastMessage
                              : 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: chat.unreadCount > 0
                                ? AppColors.textPrimary
                                : AppColors.textLight,
                            fontWeight: chat.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            chat.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'confirmed':
        return Colors.blue;
      case 'active':
      case 'in_transit':
        return AppColors.success;
      case 'completed':
      case 'returned':
        return AppColors.primaryTeal;
      case 'rejected':
      case 'cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusBadge(String status) {
    String label;
    Color color = _getStatusColor(status);

    switch (status) {
      case 'pending':
        label = 'Pending';
        break;
      case 'accepted':
        label = 'Accepted';
        break;
      case 'confirmed':
        label = 'Confirmed';
        break;
      case 'active':
        label = 'Active';
        break;
      case 'in_transit':
        label = 'In Transit';
        break;
      case 'completed':
        label = 'Completed';
        break;
      case 'returned':
        label = 'Returned';
        break;
      case 'rejected':
        label = 'Rejected';
        break;
      case 'cancelled':
        label = 'Cancelled';
        break;
      default:
        label = status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class ChatPreview {
  final String chatId;
  final String requestId;
  final String otherUserName;
  final String? otherUserProfileImage;
  final String itemName;
  final String? itemImage;
  final String? itemId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isRenter;

  ChatPreview({
    required this.chatId,
    required this.requestId,
    required this.otherUserName,
    this.otherUserProfileImage,
    required this.itemName,
    this.itemImage,
    this.itemId,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.status = 'unknown',
    this.startDate,
    this.endDate,
    this.isRenter = false,
  });

  factory ChatPreview.fromJson(Map<String, dynamic> json) {
    final requestIdObj = json['requestId'];
    final participants = json['participants'] as List?;

    String reqId = '';
    String itemName = 'Unknown Item';
    String? itemImage;
    String? itemId;
    String otherName = 'Unknown User';
    String? otherProfileImage;

    if (requestIdObj != null) {
      reqId = requestIdObj['_id'] ?? '';
      if (requestIdObj['itemId'] != null) {
        itemName = requestIdObj['itemId']['itemName'] ?? 'Unknown Item';
        itemId = requestIdObj['itemId']['_id'];
        final images = requestIdObj['itemId']['images'] as List?;
        if (images != null && images.isNotEmpty) {
          itemImage = images[0];
        }
      }
    }

    if (participants != null && participants.isNotEmpty) {
      otherName = participants[0]['name'] ?? 'Unknown User';
      otherProfileImage = participants[0]['profileImage'];
    }

    // Use otherUser if available (better approach from backend)
    if (json['otherUser'] != null) {
      otherName = json['otherUser']['name'] ?? otherName;
      otherProfileImage =
          json['otherUser']['profileImage'] ?? otherProfileImage;
    }

    return ChatPreview(
      chatId: json['_id'] ?? '',
      requestId: reqId,
      otherUserName: otherName,
      otherUserProfileImage: otherProfileImage,
      itemName: itemName,
      itemImage: itemImage,
      itemId: itemId,
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      unreadCount: json['unreadCount'] ?? 0,
      status: json['status'] ?? 'unknown',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isRenter: json['isRenter'] ?? false,
    );
  }
}
