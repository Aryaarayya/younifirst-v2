import 'package:flutter/material.dart';
import 'package:younifirst_app/models/Event_model.dart';
import 'package:younifirst_app/services/api/event_api_service.dart';
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventViewModel extends ChangeNotifier {
  List<EventModel> _events = [];
  bool _isLoading = true;
  String _errorMessage = "";
  String _selectedCategory = "Semua";
  
  // Simpan like secara lokal untuk persistensi
  Set<String> _likedEventIds = {};

  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get selectedCategory => _selectedCategory;

  EventViewModel() {
    _init();
  }

  Future<void> _init() async {
    await _loadLikedEvents();
    await fetchEvents();
  }

  String get _likeStorageKey {
    final userId = AuthService.userId ?? 'guest';
    return 'liked_event_ids_$userId';
  }

  /// Load liked events dari local storage
  Future<void> _loadLikedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likedIds = prefs.getStringList(_likeStorageKey) ?? [];
      _likedEventIds = likedIds.toSet();
    } catch (e) {
      debugPrint('Gagal load liked events: $e');
    }
  }

  /// Simpan liked events ke local storage
  Future<void> _saveLikedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_likeStorageKey, _likedEventIds.toList());
    } catch (e) {
      debugPrint('Gagal save liked events: $e');
    }
  }

  /// Cek apakah event sudah di-like secara lokal
  bool isEventLiked(String eventId) => _likedEventIds.contains(eventId);

  Future<void> fetchEvents() async {
    _isLoading = true;
    _errorMessage = "";
    notifyListeners();

    try {
      await _loadLikedEvents(); // Reload likes for the current user
      final fetchedEvents = await EventApiService.getEvents();
      final prefs = await SharedPreferences.getInstance();
      
      _events = fetchedEvents.map((e) {
        bool locallyLiked = _likedEventIds.contains(e.id);
        String finalLikesCount = e.likesCount;
        
        // Coba ambil dari cache global jika backend mengembalikan 0
        if (finalLikesCount == '0' || finalLikesCount == '') {
          final cachedCount = prefs.getString('global_likes_${e.id}');
          if (cachedCount != null) {
            finalLikesCount = cachedCount;
          }
        }
        
        // Jika di lokal di-like tapi di server count-nya masih '0', kita tampilkan setidaknya '1' 
        // agar user tidak merasa like-nya hilang saat refresh.
        if (locallyLiked && (finalLikesCount == '0' || finalLikesCount == '')) {
          finalLikesCount = '1';
        }
        
        // Update cache global jika backend mengembalikan lebih dari 0
        if (finalLikesCount != '0' && finalLikesCount != '') {
          prefs.setString('global_likes_${e.id}', finalLikesCount);
        }
        
        return e.copyWith(
          isLiked: locallyLiked,
          likesCount: finalLikesCount,
        );
      }).toList();
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
    _likedEventIds = {};
    _isLoading = true;
    _errorMessage = "";
    _selectedCategory = "Semua";
    notifyListeners();
  }

  /// Popular events: diurutkan berdasarkan likes terbanyak
  List<EventModel> get popularEvents {
    final sorted = List<EventModel>.from(_events);
    sorted.sort((a, b) {
      final likesA = int.tryParse(a.likesCount) ?? 0;
      final likesB = int.tryParse(b.likesCount) ?? 0;
      return likesB.compareTo(likesA); // Descending
    });
    return sorted.take(5).toList();
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

  /// Toggle like/unlike event (Optimistic UI + API Call)
  Future<void> toggleLike(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return;

    final event = _events[index];
    final wasLiked = event.isLiked;
    final currentLikes = int.tryParse(event.likesCount) ?? 0;

    // 1. Update lokal langsung (Optimistic UI)
    if (wasLiked) {
      _likedEventIds.remove(eventId);
    } else {
      _likedEventIds.add(eventId);
    }

    _events[index] = event.copyWith(
      isLiked: !wasLiked,
      likesCount: wasLiked 
          ? '${(currentLikes - 1).clamp(0, 999999)}' 
          : '${currentLikes + 1}',
    );
    notifyListeners();
    
    // Simpan ke local storage (user specific + global likes count)
    await _saveLikedEvents();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('global_likes_${eventId}', _events[index].likesCount);

    // 2. Panggil API Backend
    try {
      final result = await EventApiService.toggleLike(eventId);
      
      // Jika backend mengembalikan data terbaru, sinkronkan lagi agar akurat
      if (result['success'] == true) {
        final serverIsLiked = result['is_liked'] ?? !wasLiked;
        final serverLikesCount = result['likes_count']?.toString() ?? _events[index].likesCount;
        
        // Update status local set berdasarkan respon server (jika ada)
        if (result['is_liked'] != null) {
          if (serverIsLiked) {
            _likedEventIds.add(eventId);
          } else {
            _likedEventIds.remove(eventId);
          }
          await _saveLikedEvents();
        }

        _events[index] = _events[index].copyWith(
          isLiked: serverIsLiked,
          likesCount: serverLikesCount,
        );
        notifyListeners();
        
        // Simpan update terakhir dari server ke global cache
        await prefs.setString('global_likes_${eventId}', serverLikesCount);
      }
    } catch (e) {
      debugPrint('Toggle Like API error: $e');
    }
  }
}
