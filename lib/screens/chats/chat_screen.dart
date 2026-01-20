import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:rentmate/services/socket_service.dart';
import 'package:rentmate/theme/app_colors.dart';
import 'dart:convert';
import 'dart:async';
import 'package:rentmate/constants.dart';
import 'package:rentmate/item_details_screen.dart';

class ChatScreen extends StatefulWidget {
  final String requestId;
  final String currentUserId;
  final String otherUserName;
  final String? otherUserProfileImage;
  final String itemName;
  final String? chatId;
  final String? itemId;

  const ChatScreen({
    required this.requestId,
    required this.currentUserId,
    required this.otherUserName,
    this.otherUserProfileImage,
    required this.itemName,
    this.chatId,
    this.itemId,
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
  final ImagePicker _imagePicker = ImagePicker();

  List<Message> messages = [];
  bool isLoading = true;
  bool isSending = false;
  bool isUploadingImage = false;
  String? errorMessage;
  bool hasConnectionError = false;
  StreamSubscription? _connectionSubscription;
  bool isSelfChat = false;
  String? _currentChatId;

  // Rent request details
  String _requestStatus = 'unknown';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isRenter = false;
  bool _isAccepting = false;
  String? _itemId;

  // Design colors
  static const Color _sentBubbleColor = Color(0xFF1C1C1E); // Black/dark
  static const Color _sentTextColor = Colors.white;
  static const Color _receivedBubbleColor = Color(0xFF1C1C1E); // Black/dark
  static const Color _receivedTextColor = Colors.white;
  static const Color _timestampColor = Color(0xFF9E9E9E);

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

  Future<void> _markMessagesAsRead() async {
    try {
      await http.put(
        Uri.parse('$kBaseUrl/chat/request/${widget.requestId}/read'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': widget.currentUserId}),
      );
    } catch (e) {
      print('Error marking messages as read: $e');
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
      }
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  Future<void> _checkRequestDetails() async {
    // Initialize from widget if available
    if (widget.itemId != null && _itemId == null) {
      _itemId = widget.itemId;
    }

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

        // Extract itemId from response
        String? itemIdFromApi;
        if (data['itemId'] is Map) {
          itemIdFromApi = data['itemId']['_id'];
        } else if (data['itemId'] is String) {
          itemIdFromApi = data['itemId'];
        }

        if (mounted) {
          setState(() {
            isSelfChat = customerId.toString() == renterId.toString();
            _requestStatus = data['status'] ?? 'unknown';
            _isRenter = renterId.toString() == widget.currentUserId;
            if (data['startDate'] != null) {
              _startDate = DateTime.parse(data['startDate']);
            }
            if (data['endDate'] != null) {
              _endDate = DateTime.parse(data['endDate']);
            }
            // Set itemId if not already set from widget
            if (_itemId == null && itemIdFromApi != null) {
              _itemId = itemIdFromApi;
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching request details: $e');
    }
  }

  Future<void> _acceptRequest() async {
    setState(() => _isAccepting = true);
    try {
      final response = await http.put(
        Uri.parse('$kBaseUrl/rent-request/${widget.requestId}/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': 'accepted'}),
      );

      if (response.statusCode == 200) {
        setState(() => _requestStatus = 'accepted');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request accepted!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      print('Error accepting request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isAccepting = false);
    }
  }

  Future<void> _rejectRequest() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Request'),
        content: Text('Are you sure you want to reject this rental request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reject', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isAccepting = true);
    try {
      final response = await http.put(
        Uri.parse('$kBaseUrl/rent-request/${widget.requestId}/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': 'rejected'}),
      );

      if (response.statusCode == 200) {
        setState(() => _requestStatus = 'rejected');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request rejected')),
        );
      }
    } catch (e) {
      print('Error rejecting request: $e');
    } finally {
      setState(() => _isAccepting = false);
    }
  }

  void _initializeChat() {
    _socketService.connect();

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
        _markMessagesAsRead();
      } catch (e) {
        print('Error processing chat history: $e');
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
        if (newMessage.senderId != widget.currentUserId) {
          _markMessagesAsRead();
        }
      } catch (e) {
        print('Error parsing new message: $e');
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

  Future<void> _pickAndSendImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    setState(() => isUploadingImage = true);

    try {
      final uri = Uri.parse('$kBaseUrl/upload');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          pickedFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final imageUrl = data['url'];

        _socketService.sendMessage(
          widget.requestId,
          widget.currentUserId,
          '',
          imageUrl: imageUrl,
          messageType: 'image',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => isUploadingImage = false);
    }
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageView(imageUrl: imageUrl),
      ),
    );
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
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              // Avatar with profile image
              CircleAvatar(
                backgroundColor: _sentBubbleColor,
                radius: 20,
                backgroundImage:
                    widget.otherUserProfileImage != null &&
                        widget.otherUserProfileImage!.isNotEmpty
                    ? NetworkImage(widget.otherUserProfileImage!)
                    : null,
                child:
                    widget.otherUserProfileImage == null ||
                        widget.otherUserProfileImage!.isEmpty
                    ? Text(
                        widget.otherUserName.isNotEmpty
                            ? widget.otherUserName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUserName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.itemName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Connection indicator
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _socketService.isConnected
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            if (isSelfChat)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: AppColors.warning.withOpacity(0.1),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Self-Chat Mode',
                      style: TextStyle(color: AppColors.warning, fontSize: 13),
                    ),
                  ],
                ),
              ),
            if (hasConnectionError && errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: AppColors.error.withOpacity(0.1),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            _buildStatusHeader(),
            Expanded(child: _buildMessagesList()),
            _buildInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    if (_requestStatus == 'unknown') return const SizedBox.shrink();

    Color statusColor;
    String statusLabel;

    switch (_requestStatus) {
      case 'pending':
        statusColor = Colors.orange;
        statusLabel = 'Pending Request';
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusLabel = 'Request Accepted';
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusLabel = 'Request Rejected';
        break;
      case 'active':
        statusColor = AppColors.success;
        statusLabel = 'Active Rental';
        break;
      case 'completed':
        statusColor = AppColors.primaryTeal;
        statusLabel = 'Completed';
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusLabel = 'Cancelled';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = _requestStatus;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (_startDate != null && _endDate != null)
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                // View Item button
                if (_itemId != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemDetailScreen(
                              itemId: _itemId!,
                              currentUserId: widget.currentUserId,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primaryTeal.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.open_in_new,
                              size: 14,
                              color: AppColors.primaryTeal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'View Item',
                              style: TextStyle(
                                color: AppColors.primaryTeal,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Show actions only for renter (owner) when pending
          if (_isRenter && _requestStatus == 'pending')
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isAccepting ? null : _rejectRequest,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                          vertical: 0,
                        ), // Slimmer
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isAccepting ? null : _acceptRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        minimumSize: const Size(0, 36),
                        elevation: 0,
                      ),
                      child: _isAccepting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Accept Request'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryTeal),
      );
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Start the conversation!',
              style: TextStyle(color: AppColors.textLight, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == widget.currentUserId;

        // Check if we should show date divider
        bool showDateDivider = false;
        if (index == 0) {
          showDateDivider = true;
        } else {
          showDateDivider = _shouldShowDateDivider(
            messages[index - 1].timestamp,
            message.timestamp,
          );
        }

        return Column(
          children: [
            if (showDateDivider) _buildDateDivider(message.timestamp),
            GestureDetector(
              onLongPress: () {
                if (isMe) _deleteMessage(message.messageId);
              },
              child: message.messageType == 'image'
                  ? _buildImageMessage(message, isMe)
                  : _buildTextMessage(message, isMe),
            ),
          ],
        );
      },
    );
  }

  bool _shouldShowDateDivider(DateTime prev, DateTime curr) {
    return prev.year != curr.year ||
        prev.month != curr.month ||
        prev.day != curr.day;
  }

  Widget _buildTextMessage(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for received messages
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: _sentBubbleColor,
              radius: 16,
              backgroundImage:
                  widget.otherUserProfileImage != null &&
                      widget.otherUserProfileImage!.isNotEmpty
                  ? NetworkImage(widget.otherUserProfileImage!)
                  : null,
              child:
                  widget.otherUserProfileImage == null ||
                      widget.otherUserProfileImage!.isEmpty
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],

          // Message content
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? _sentBubbleColor : _receivedBubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isMe
                          ? const Radius.circular(20)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? _sentTextColor : _receivedTextColor,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),

                // Timestamp below bubble
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: _timestampColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for received messages
          if (!isMe) ...[
            CircleAvatar(
              backgroundColor: _sentBubbleColor,
              radius: 16,
              child: Text(
                widget.otherUserName.isNotEmpty
                    ? widget.otherUserName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Image content
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (message.imageUrl != null) {
                      _showFullScreenImage(message.imageUrl!);
                    }
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.65,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isMe ? _sentBubbleColor : _receivedBubbleColor,
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.network(
                        message.imageUrl ?? '',
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey.shade100,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                color: AppColors.primaryTeal,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textLight,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Timestamp below image
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: _timestampColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade600.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _formatDateDivider(date),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateDivider(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      // Within last week - show day name
      const days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return days[date.weekday - 1];
    } else {
      // Older - show full date
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Image picker button
            GestureDetector(
              onTap: isUploadingImage ? null : _pickAndSendImage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: isUploadingImage
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryTeal,
                        ),
                      )
                    : Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: AppColors.textLight),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Send button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _sentBubbleColor,
                  shape: BoxShape.circle,
                ),
                child: isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

// Full screen image viewer
class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({Key? key, required this.imageUrl})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                      : null,
                  color: AppColors.primaryTeal,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class Message {
  final String messageId;
  final String senderId;
  final String text;
  final String messageType;
  final String? imageUrl;
  final DateTime timestamp;

  Message({
    this.messageId = '',
    required this.senderId,
    required this.text,
    this.messageType = 'text',
    this.imageUrl,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['_id'] ?? '',
      senderId: json['senderId'] ?? '',
      text: json['text'] ?? '',
      messageType: json['messageType'] ?? 'text',
      imageUrl: json['imageUrl'],
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
