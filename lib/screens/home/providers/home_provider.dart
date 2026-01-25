import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../constants.dart';
import '../../../models/item_model.dart';

class HomeProvider extends ChangeNotifier {
  List<ItemModel> _allItems = [];
  List<ItemModel> _filteredItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ItemModel> get items => _filteredItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasItems => _filteredItems.isNotEmpty;

  // Load all items
  Future<void> loadItems() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$kBaseUrl/item/fetch-all'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final itemsJson = data['items'] as List;

        _allItems = itemsJson.map((json) => ItemModel.fromJson(json)).toList();
        _filteredItems = _allItems;
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to load items';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
      print('Error loading items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search items
  Future<void> searchItems(String query) async {
    if (query.isEmpty) {
      _filteredItems = _allItems;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse(
          '$kBaseUrl/item/fetch-all?search=${Uri.encodeComponent(query)}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final itemsJson = data['items'] as List;

        _filteredItems = itemsJson
            .map((json) => ItemModel.fromJson(json))
            .toList();
        _errorMessage = null;
      } else {
        _errorMessage = 'Search failed';
      }
    } catch (e) {
      _errorMessage = 'Search error: $e';
      print('Error searching items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear search
  void clearSearch() {
    _filteredItems = _allItems;
    notifyListeners();
  }

  // Refresh items
  Future<void> refreshItems() async {
    await loadItems();
  }
}
