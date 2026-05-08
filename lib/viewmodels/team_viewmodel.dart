import 'package:flutter/material.dart';
import 'package:younifirst_app/models/Teams_model.dart';
import 'package:younifirst_app/services/api/team_api_service.dart';

class TeamViewModel extends ChangeNotifier {
  List<TeamModel> _allTeams = [];
  List<TeamModel> _myTeams = [];
  
  bool _isLoadingAll = true;
  bool _isLoadingMy = true;
  
  String _errorAll = "";
  String _errorMy = "";
  
  String _searchQuery = "";

  List<TeamModel> get allTeams => _allTeams;
  List<TeamModel> get myTeams => _myTeams;
  
  bool get isLoadingAll => _isLoadingAll;
  bool get isLoadingMy => _isLoadingMy;
  
  String get errorAll => _errorAll;
  String get errorMy => _errorMy;
  
  String get searchQuery => _searchQuery;

  TeamViewModel() {
    fetchAllTeams();
    fetchMyTeams();
  }

  Future<void> fetchAllTeams() async {
    _isLoadingAll = true;
    _errorAll = "";
    notifyListeners();

    try {
      final fetchedTeams = await TeamApiService.getTeams();
      _allTeams = fetchedTeams;
    } catch (e) {
      _errorAll = e.toString().replaceAll('Exception: ', '');
      debugPrint("Fetch All Teams Error: $e");
    } finally {
      _isLoadingAll = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyTeams() async {
    _isLoadingMy = true;
    _errorMy = "";
    notifyListeners();

    try {
      final fetchedTeams = await TeamApiService.getMyTeams();
      _myTeams = fetchedTeams;
    } catch (e) {
      _errorMy = e.toString().replaceAll('Exception: ', '');
      debugPrint("Fetch My Teams Error: $e");
    } finally {
      _isLoadingMy = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<TeamModel> get filteredAllTeams {
    if (_searchQuery.isEmpty) return _allTeams;
    final q = _searchQuery.toLowerCase();
    return _allTeams
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            t.lombaName.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q))
        .toList();
  }
}
