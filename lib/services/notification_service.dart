import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class NotificationService {
  /// Get all notifications for a user
  static Future<Map<String, dynamic>> getNotifications(
    String userId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$kBaseUrl/notification/user/$userId?page=$page&limit=$limit',
        ),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to fetch notifications: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Get unread notification count for a user
  static Future<int> getUnreadCount(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/notification/user/$userId/unread-count'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        throw Exception('Failed to fetch unread count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0; // Return 0 on error to avoid breaking UI
    }
  }

  /// Mark a single notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$kBaseUrl/notification/$notificationId/read'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read for a user
  static Future<bool> markAllAsRead(String userId) async {
    try {
      final response = await http.put(
        Uri.parse('$kBaseUrl/notification/user/$userId/read-all'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking all as read: $e');
      return false;
    }
  }

  /// Delete a notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$kBaseUrl/notification/$notificationId'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }
}
