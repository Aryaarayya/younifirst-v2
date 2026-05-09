import 'package:younifirst_app/services/api/user_api_service.dart';
import 'package:flutter/material.dart';
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:younifirst_app/services/api/lostandfound_api_service.dart';

class ProfilViewModel extends ChangeNotifier {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  ProfilViewModel() {
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await UserApiService.getCurrentUser();
      debugPrint("📸 User data fetched: $data");
      debugPrint("📸 Photo field: '${data['photo']}'");
      _userData = data;
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _userData = null;
    notifyListeners();
  }
}

