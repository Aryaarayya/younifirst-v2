import 'package:flutter/material.dart';
import 'package:younifirst_app/models/Event_model.dart';
import 'package:younifirst_app/services/event_api_service.dart';
import 'package:younifirst_app/pages/event/EventDetail_pages.dart';

class PopularEventPage extends StatefulWidget {
  @override
  _PopularEventPageState createState() => _PopularEventPageState();
}

class _PopularEventPageState extends State<PopularEventPage> {
  List<EventModel> events = [];
  List<EventModel> filteredEvents = [];
  bool isLoading = true;
  String errorMessage = "";
  String _selectedCategory = "Semua";

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final fetchedEvents = await EventApiService.getEvents();
      setState(() {
        // Tampilkan semua event (atau filter populer jika backend mendukung)
        events = fetchedEvents;
        _filterByCategory();
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString().replaceAll('Exception: ', '');
          isLoading = false;
        });
      }
    }
  }

  void _filterByCategory() {
    if (_selectedCategory == "Semua") {
      filteredEvents = List.from(events);
    } else {
      final categoryMapping = {
        'Kompetisi': '1',
        'Seminar': '2',
        'Pameran': '3',
        'Turnamen': '4',
        'Konser': '5',
      };
      final catId = categoryMapping[_selectedCategory];
      
      filteredEvents = events.where((e) {
         if (catId != null && e.categoryId == catId) return true;
         return false;
      }).toList();
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _filterByCategory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Popular Events 🔥",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildCategoryChips(),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: fetchEvents,
                child: _buildEventGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip("Semua", Icons.check_circle, _selectedCategory == "Semua"),
          _buildChip("Kompetisi", Icons.emoji_events_outlined, _selectedCategory == "Kompetisi"),
          _buildChip("Seminar", Icons.mic_none, _selectedCategory == "Seminar"),
          _buildChip("Pameran", Icons.palette_outlined, _selectedCategory == "Pameran"),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => _onCategorySelected(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3D5AFE) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3D5AFE) : const Color(0xFF3D5AFE),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF3D5AFE),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF3D5AFE),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventGrid() {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.65,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            return _buildSkeletonCard(); // Tampilkan skeleton saat loading sesuai desain!
          },
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text("Error: $errorMessage", style: const TextStyle(color: Colors.red)),
      );
    }

    if (filteredEvents.isEmpty) {
      return const Center(child: Text("Tidak ada event."));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.65,
        ),
        itemCount: filteredEvents.length,
        itemBuilder: (context, index) {
          final ev = filteredEvents[index];
          return _buildMiniEventCard(
            id: ev.id,
            imageUrl: ev.imageUrl,
            title: ev.title,
            date: ev.date,
            time: ev.time,
            location: ev.location,
            likes: ev.likesCount,
            liked: int.tryParse(ev.likesCount) != null && int.parse(ev.likesCount) > 0,
          );
        },
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 10, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Expanded(child: Container(height: 10, color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 10, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Expanded(child: Container(height: 10, color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Container(height: 10, width: 15, color: Colors.grey[300]),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D5AFE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(width: 20, height: 8, color: Colors.transparent),
                          const Icon(Icons.arrow_forward, color: Colors.white, size: 10),
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniEventCard({
    required String id,
    required String imageUrl,
    required String title,
    required String date,
    required String time,
    required String location,
    required String likes,
    required bool liked,
  }) {
    bool isNetworkImage = imageUrl.toLowerCase().startsWith('http');

    return GestureDetector(
      onTap: () async {
        if (id.isNotEmpty) {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailPage(eventId: id),
            ),
          );
          if (result == true) {
            fetchEvents();
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: isNetworkImage
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image, color: Colors.grey),
                          )
                        : Image.asset(
                            'assets/images/Younifirst.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.calendar_today, size: 10, color: Color(0xFF3D5AFE)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          time.isNotEmpty ? "$date • $time" : date,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black54, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 10, color: Color(0xFF3D5AFE)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.black54, fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite, size: 14, color: liked ? Colors.red : Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            likes,
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D5AFE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: const [
                            Text("Mulai", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 10),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
