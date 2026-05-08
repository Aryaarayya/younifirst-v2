import 'package:flutter/material.dart';
import 'package:younifirst_app/models/Event_model.dart';
import 'package:younifirst_app/services/api/event_api_service.dart';

class EventViewModel extends ChangeNotifier {
  List<EventModel> _events = [];
  bool _isLoading = true;
  String _errorMessage = "";
  String _selectedCategory = "Semua";

  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  EventViewModel() {
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    _isLoading = true;
    _errorMessage = "";
    notifyListeners();

    try {
      final fetchedEvents = await EventApiService.getEvents();
      _events = fetchedEvents; // Backend already sorts newest first
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint("Fetch Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  List<EventModel> get popularEvents {
    // Ambil maksimal 3 event pertama sebagai event populer
    return _events.take(3).toList();
  }

  List<EventModel> get filteredEvents {
    if (_selectedCategory == "Semua") {
      return List.from(_events);
    }

    final categoryMapping = {
      'Kompetisi': '1',
      'Seminar': '2',
      'Pameran': '3',
      'Turnamen': '4',
      'Konser': '5',
    };
    
    final catId = categoryMapping[_selectedCategory];
    return _events.where((e) => e.categoryId == catId).toList();
  }
}
