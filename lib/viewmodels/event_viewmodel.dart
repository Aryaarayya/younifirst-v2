import 'package:flutter/material.dart';
import 'package:younifirst_app/models/Event_model.dart';
import 'package:younifirst_app/services/api/event_api_service.dart';
import 'package:younifirst_app/services/input/auth_service.dart';

class EventViewModel extends ChangeNotifier {
  List<EventModel> _events = [];
  List<EventModel> _myPendingEvents = [];
  bool _isLoading = true;
  String _errorMessage = "";
  String _selectedCategory = "Semua";

  List<EventModel> get events => _events;
  List<EventModel> get myPendingEvents => _myPendingEvents;
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

      // Gunakan isLiked LANGSUNG dari server sebagai sumber kebenaran.
      // Jangan override dengan local cache — itu menyebabkan mismatch
      // yang membuat like malah jadi unlike di server.
      _events = fetchedEvents;

      if (AuthService.userId != null) {
        _myPendingEvents = await EventApiService.getMyPendingEvents();
      }
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

  void clear() {
    _events = [];
    _myPendingEvents = [];
    _isLoading = true;
    _errorMessage = "";
    _selectedCategory = "Semua";
    notifyListeners();
  }

  /// Popular events: diurutkan berdasarkan likes terbanyak
  List<EventModel> get popularEvents {
    // Hanya tampilkan event yang active/open di feed publik
    final activeEvents = _events.where((e) {
      final status = e.status.toLowerCase();
      return status != 'pending' && status != 'menunggu' && status != 'review' && status != '0' && status != 'false' && status != 'cancelled';
    }).toList();

    final sorted = List<EventModel>.from(activeEvents);
    sorted.sort((a, b) {
      final likesA = int.tryParse(a.likesCount) ?? 0;
      final likesB = int.tryParse(b.likesCount) ?? 0;
      return likesB.compareTo(likesA); // Descending
    });
    return sorted.take(5).toList();
  }

  List<EventModel> get filteredEvents {
    // Hanya tampilkan event yang active/open di feed publik
    final activeEvents = _events.where((e) {
      final status = e.status.toLowerCase();
      return status != 'pending' && status != 'menunggu' && status != 'review' && status != '0' && status != 'false' && status != 'cancelled';
    }).toList();

    if (_selectedCategory == "Semua") {
      return List.from(activeEvents);
    }

    final categoryMapping = {
      'Seminar': '1',
      'Workshop': '2',
      'Kompetisi': '3',
      'Festival': '4',
      'Olahraga': '5',
      'Seni & Budaya': '6',
      'Akademik': '7',
      'Sosial': '8',
    };

    final catId = categoryMapping[_selectedCategory];
    return activeEvents.where((e) => e.categoryId == catId).toList();
  }

  /// Toggle like/unlike event (Optimistic UI + API Call)
  Future<void> toggleLike(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    final event = _events[index];
    final wasLiked = event.isLiked;
    final currentLikes = int.tryParse(event.likesCount) ?? 0;

    // 1. Optimistic UI — update tampilan langsung sebelum API selesai
    _events[index] = event.copyWith(
      isLiked: !wasLiked,
      likesCount: wasLiked
          ? '${(currentLikes - 1).clamp(0, 999999)}'
          : '${currentLikes + 1}',
    );
    notifyListeners();

    // 2. Panggil API Backend
    try {
      final result = await EventApiService.toggleLike(eventId);

      if (result['success'] == true) {
        // Sinkronkan dengan data AKURAT dari server
        final serverIsLiked = result['is_liked'] ?? !wasLiked;
        final serverLikesCount = result['likes_count']?.toString() ?? _events[index].likesCount;

        _events[index] = _events[index].copyWith(
          isLiked: serverIsLiked,
          likesCount: serverLikesCount,
        );
        notifyListeners();
      }
    } catch (e) {
      // Revert ke state semula jika API gagal
      debugPrint('Toggle Like API error: $e');
      _events[index] = event.copyWith(
        isLiked: wasLiked,
        likesCount: currentLikes.toString(),
      );
      notifyListeners();
    }
  }
}
