import 'package:flutter/material.dart';
import 'package:younifirst_app/models/lost_found_model.dart';
import 'package:younifirst_app/services/api/lostandfound_api_service.dart';
import 'package:younifirst_app/services/input/auth_service.dart';

class BarangViewModel extends ChangeNotifier {
  List<LostFoundModel> _allData = [];
  bool _isLoading = true;
  String _errorMessage = "";

  int _selectedFilterIndex = 0;
  final List<String> filters = ['Semua', 'Hilang', 'Ditemukan'];
  String _searchQuery = "";

  List<LostFoundModel> get allData => _allData;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get selectedFilterIndex => _selectedFilterIndex;
  String get searchQuery => _searchQuery;

  BarangViewModel() {
    fetchBarang();
  }

  Future<void> fetchBarang() async {
    _isLoading = true;
    _errorMessage = "";
    notifyListeners();

    try {
      final data = await LostFoundApiService.getLostAndFound();
      _allData = data;
      
      // Cleanup expired posts belonging to current user in background
      _cleanupExpiredPosts();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint("Fetch Barang Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilterIndex(int index) {
    _selectedFilterIndex = index;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = "";
    notifyListeners();
  }

  List<LostFoundModel> get filteredData {
    String query = _searchQuery.toLowerCase();

    return _allData.where((item) {
      // Hide completed items from the main feed
      if (item.isCompleted) return false;

      // Apply Filter Category
      bool matchesFilter = true;
      if (_selectedFilterIndex != 0) {
        matchesFilter = item.type == filters[_selectedFilterIndex];
      }

      // Apply Search Query
      bool matchesSearch = item.itemName.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query) ||
          item.userName.toLowerCase().contains(query);

      return matchesFilter && matchesSearch && !item.isExpired;
    }).toList();
  }

  /// Marks an item as completed in local state (instant UI update).
  void markItemCompleted(String lostFoundId) {
    final idx = _allData.indexWhere((e) => e.lostfoundId == lostFoundId);
    if (idx == -1) return;
    final old = _allData[idx];
    _allData[idx] = LostFoundModel(
      lostfoundId: old.lostfoundId,
      userId: old.userId,
      userName: old.userName,
      userEmail: old.userEmail,
      userNim: old.userNim,
      userProdi: old.userProdi,
      userAvatar: old.userAvatar,
      type: old.type,
      statusId: old.statusId,
      itemName: old.itemName,
      location: old.location,
      description: old.description,
      imageUrl: old.imageUrl,
      createdAt: old.createdAt,
      likesCount: old.likesCount,
      commentsCount: old.commentsCount,
      isCompleted: true, // Mark as completed
      isLiked: old.isLiked,
    );
    notifyListeners();
  }

  /// Automatically deletes expired posts belonging to the logged-in user from the server.
  Future<void> _cleanupExpiredPosts() async {
    final String? currentUserId = AuthService.loggedInUserId;
    if (currentUserId == null) return;

    final expiredMine = _allData.where((item) => item.isExpired && item.userId == currentUserId).toList();
    
    if (expiredMine.isEmpty) return;

    debugPrint("Cleaning up ${expiredMine.length} expired posts...");
    
    for (var item in expiredMine) {
      try {
        await LostFoundApiService.deleteLostFound(item.lostfoundId);
      } catch (e) {
        debugPrint("Failed to auto-delete expired post ${item.lostfoundId}: $e");
      }
    }
  }
}

