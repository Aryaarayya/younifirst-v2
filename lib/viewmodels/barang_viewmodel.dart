import 'package:flutter/material.dart';
import 'package:younifirst_app/models/lost_found_model.dart';
import 'package:younifirst_app/services/api/lostandfound_api_service.dart';

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

      return matchesFilter && matchesSearch;
    }).toList();
  }
}
