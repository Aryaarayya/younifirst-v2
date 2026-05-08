import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:younifirst_app/models/Event_model.dart';
import 'package:younifirst_app/services/api/event_api_service.dart';
import 'package:younifirst_app/views/event/TambahEvent_pages.dart';
import 'package:younifirst_app/views/event/UpdateEvent_pages.dart';
import 'package:younifirst_app/views/event/EventDetail_pages.dart';
import 'package:younifirst_app/views/event/PopularEvent_pages.dart';
import 'package:younifirst_app/widgets/notification_bell.dart';
import 'package:provider/provider.dart';
import 'package:younifirst_app/viewmodels/event_viewmodel.dart';

class EventPage extends StatefulWidget {
  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventViewModel>().fetchEvents();
    });
  }

  void _showFilterModal(BuildContext context, EventViewModel viewModel) {
    String tempSelected = viewModel.selectedCategory;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Filter",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.withOpacity(0.2), thickness: 1),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildModalChip("Semua", Icons.check_circle, tempSelected == "Semua", () {
                        setModalState(() => tempSelected = "Semua");
                      }),
                      _buildModalChip("Kompetisi", Icons.emoji_events_outlined, tempSelected == "Kompetisi", () {
                        setModalState(() => tempSelected = "Kompetisi");
                      }),
                      _buildModalChip("Seminar", Icons.mic_external_on_outlined, tempSelected == "Seminar", () {
                        setModalState(() => tempSelected = "Seminar");
                      }),
                      _buildModalChip("Pameran", Icons.palette_outlined, tempSelected == "Pameran", () {
                        setModalState(() => tempSelected = "Pameran");
                      }),
                      _buildModalChip("Turnamen", Icons.sports_esports_outlined, tempSelected == "Turnamen", () {
                        setModalState(() => tempSelected = "Turnamen");
                      }),
                      _buildModalChip("Konser", Icons.music_note_outlined, tempSelected == "Konser", () {
                        setModalState(() => tempSelected = "Konser");
                      }),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            setModalState(() => tempSelected = "Semua");
                            viewModel.setSelectedCategory("Semua");
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F6FF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Reset",
                            style: TextStyle(
                              color: Color(0xFF3D5AFE),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            viewModel.setSelectedCategory(tempSelected);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D5AFE),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                            shadowColor: const Color(0xFF3D5AFE).withOpacity(0.3),
                          ),
                          child: const Text(
                            "Terapkan",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalChip(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3D5AFE) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF3D5AFE).withOpacity(isSelected ? 1.0 : 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF3D5AFE),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF3D5AFE),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Consumer<EventViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            child: Stack(
              children: [
                // Blue Background Top
                Container(
                  height: 250,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3D5AFE),
                  ),
                ),
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(viewModel),
                      const SizedBox(height: 20),
                      _buildPopularEventsHeader(),
                      const SizedBox(height: 16),
                      _buildPopularEventsList(viewModel),
                      const SizedBox(height: 24),
                      _buildCategoryHeader(),
                      const SizedBox(height: 12),
                      _buildCategoryChips(viewModel),
                      const SizedBox(height: 16),
                      _buildEventGrid(viewModel),
                      const SizedBox(height: 80), // Padding for FAB
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TambahEventPage(),
            ),
          );
          if (result == true) {
            context.read<EventViewModel>().fetchEvents();
          }
        },
        backgroundColor: const Color(0xFF3D5AFE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildHeader(EventViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(  
                    'assets/images/logo_putih.png',
                    width: 35,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Event",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              NotificationBell(iconColor: Colors.white),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Temukan events...",
                      hintStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.search, color: Colors.white70),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showFilterModal(context, viewModel),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune_outlined, color: Colors.white),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopularEventsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Popular Events 🔥",
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PopularEventPage()));
            },
            child: const Text(
              "LIHAT SEMUA",
              style: TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularEventsList(EventViewModel viewModel) {
    if (viewModel.isLoading) {
      return const SizedBox(
        height: 380,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (viewModel.errorMessage.isNotEmpty) {
      return SizedBox(
        height: 380,
        child: Center(
            child: Text(viewModel.errorMessage, style: const TextStyle(color: Colors.white))),
      );
    }

    if (viewModel.events.isEmpty) {
      return const SizedBox(
        height: 380,
        child: Center(
            child: Text("Belum ada event populer.", 
                       style: TextStyle(color: Colors.white))),
      );
    }

    final popularEvents = viewModel.popularEvents;

    return SizedBox(
      height: 450,
      child: RefreshIndicator(
        onRefresh: viewModel.fetchEvents,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: popularEvents.length,
          itemBuilder: (context, index) {
            final ev = popularEvents[index];
              return _buildEventCard(
                id: ev.id,
                imageUrl: ev.imageUrl, // Bisa ditambahkan network logic jika url valid
                title: ev.title,
                date: ev.date,
                time: ev.time,
                location: ev.location,
                likes: ev.likesCount,
                viewModel: viewModel,
              );
          },
        ),
      ),
    );
  }



  Widget _buildEventCard({
    required String id,
    required String imageUrl,
    required String title,
    required String date,
    required String time,
    required String location,
    required String likes,
    required EventViewModel viewModel,
  }) {
    bool isNetworkImage = imageUrl.toLowerCase().startsWith('http');

    return GestureDetector(
      onTap: () async {
        if (id.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID event tidak valid dari server')));
          return;
        }
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(eventId: id),
          ),
        );
        if (result == true) {
          viewModel.fetchEvents();
        }
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16, bottom: 10, top: 5, left: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  height: 220,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: isNetworkImage
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        )
                      : Image.asset(
                          'assets/images/Younifirst.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image, size: 50, color: Colors.grey),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 16, color: Color(0xFF3D5AFE)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          time.isNotEmpty ? "$date  •  $time" : date,
                          style: TextStyle(
                              color: Colors.black.withOpacity(0.6), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF3D5AFE)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.black.withOpacity(0.6), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey.withOpacity(0.2), thickness: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite_border, size: 22, color: Colors.black.withOpacity(0.7)),
                          const SizedBox(width: 8),
                          Text(
                            likes,
                            style: TextStyle(
                                color: Colors.black.withOpacity(0.8),
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3D5AFE),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3D5AFE).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: const [
                            Text("Mulai",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Pilih berdasarkan Kategori ✨",
            style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PopularEventPage()));
            },
            child: const Text(
              "LIHAT SEMUA",
              style: TextStyle(
                  color: Color(0xFF3D5AFE),
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(EventViewModel viewModel) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip("Semua", Icons.check_circle, viewModel.selectedCategory == "Semua", viewModel),
          _buildChip("Kompetisi", Icons.emoji_events_outlined, viewModel.selectedCategory == "Kompetisi", viewModel),
          _buildChip("Seminar", Icons.mic_external_on_outlined, viewModel.selectedCategory == "Seminar", viewModel),
          _buildChip("Pameran", Icons.palette_outlined, viewModel.selectedCategory == "Pameran", viewModel),
          _buildChip("Turnamen", Icons.sports_esports_outlined, viewModel.selectedCategory == "Turnamen", viewModel),
          _buildChip("Konser", Icons.music_note_outlined, viewModel.selectedCategory == "Konser", viewModel),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, bool isSelected, EventViewModel viewModel) {
    return GestureDetector(
      onTap: () {
        viewModel.setSelectedCategory(label);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3D5AFE) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF3D5AFE).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
          border: Border.all(
            color: isSelected ? const Color(0xFF3D5AFE) : const Color(0xFF3D5AFE).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF3D5AFE),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF3D5AFE),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventGrid(EventViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage.isNotEmpty) {
      return Center(
          child: IconButton(
              icon: Icon(Icons.refresh), onPressed: viewModel.fetchEvents)); 
    }

    List<EventModel> filteredEvents = viewModel.filteredEvents;

    if (filteredEvents.isEmpty) {
      return const Center(child: Text("Tidak ada data untuk kategori ini."));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.6,
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
            liked: int.tryParse(ev.likesCount) != null && int.parse(ev.likesCount) > 0, // dummy logic for liked statis
            viewModel: viewModel,
          );
        },
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
    required EventViewModel viewModel,
  }) {
    bool isSkeleton = title == "Loading...";
    bool isNetworkImage = imageUrl.toLowerCase().startsWith('http');

    return GestureDetector(
      onTap: () async {
        if (!isSkeleton) {
          if (id.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID event tidak valid dari server')));
            return;
          }
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailPage(eventId: id),
            ),
          );
          if (result == true) {
            viewModel.fetchEvents();
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: isSkeleton
                          ? null
                          : (isNetworkImage
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image, color: Colors.grey),
                                )
                              : Image.asset(
                                  'assets/images/icon_login.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image, color: Colors.grey),
                                )),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isSkeleton
                      ? Container(height: 12, width: 80, color: Colors.grey[200])
                      : Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                        ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_month,
                          size: 12,
                          color: isSkeleton
                              ? Colors.grey[300]
                              : const Color(0xFF3D5AFE)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: isSkeleton
                            ? Container(height: 10, color: Colors.grey[200])
                            : Text(
                                time.isNotEmpty ? "$date" : date,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.black54, fontSize: 10),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 12,
                          color: isSkeleton
                              ? Colors.grey[300]
                              : const Color(0xFF3D5AFE)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: isSkeleton
                            ? Container(height: 10, color: Colors.grey[200])
                            : Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.black54, fontSize: 10),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(color: Colors.grey.withOpacity(0.15), thickness: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.favorite_border,
                              size: 18,
                              color: isSkeleton
                                  ? Colors.grey[300]
                                  : Colors.black.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          isSkeleton
                              ? Container(height: 10, width: 15, color: Colors.grey[200])
                              : Text(
                                  likes,
                                  style: TextStyle(
                                      color: Colors.black.withOpacity(0.7),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSkeleton
                              ? Colors.grey[200]
                              : const Color(0xFF3D5AFE),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.arrow_forward, color: Colors.white, size: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
