import 'package:flutter/material.dart';
import 'package:younifirst_app/models/lost_found_model.dart';
import 'package:younifirst_app/services/api/lostandfound_api_service.dart';
import 'package:younifirst_app/services/api/user_api_service.dart';
import 'package:intl/intl.dart';

class BarangDetailPage extends StatefulWidget {
  final String lostFoundId;
  final LostFoundModel? initialData;

  const BarangDetailPage({super.key, required this.lostFoundId, this.initialData});

  @override
  State<BarangDetailPage> createState() => _BarangDetailPageState();
}

class _BarangDetailPageState extends State<BarangDetailPage> {
  late Future<LostFoundModel> _itemFuture;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _itemFuture = Future.value(widget.initialData);
    } else {
      _itemFuture = LostFoundApiService.getLostFoundById(widget.lostFoundId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder<LostFoundModel>(
        future: _itemFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Gagal memuat detail: ${snapshot.error}"),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _itemFuture = LostFoundApiService.getLostFoundById(widget.lostFoundId);
                    }),
                    child: const Text("Coba Lagi"),
                  )
                ],
              ),
            );
          }

          final item = snapshot.data!;
          final isDitemukan = item.type == 'Ditemukan';
          final dateStr = item.createdAt != null 
              ? DateFormat('dd MMMM yyyy').format(DateTime.parse(item.createdAt!))
              : 'Unknown Date';

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 🔥 HERO SLIVER APP BAR
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF3D5AFE),
                leading: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      item.imageUrl != null
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: const Color(0xFFF0F4FA),
                              child: const Icon(Icons.image_outlined, size: 100, color: Colors.grey),
                            ),
                      // Gradient overlay for better text readability
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black26, Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 🔥 CONTENT SLIVER
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kategori & Tanggal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDitemukan ? const Color(0xFF3D5AFE) : const Color(0xFF3D5AFE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item.type.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            Text(
                              dateStr,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Nama Barang
                        Text(
                          item.itemName,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 12),

                        // Lokasi
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFF3D5AFE), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.location,
                                style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 24),

                        // Poster Info
                        Row(
                          children: [
                            Builder(
                              builder: (context) {
                                String userName = item.userName ?? 'Mahasiswa';
                                String initial = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'M';
                                String? fullAvatarUrl;
                                if (item.userAvatar != null && item.userAvatar!.isNotEmpty && item.userAvatar != 'null') {
                                  fullAvatarUrl = item.userAvatar!.startsWith('http') ? item.userAvatar : LostFoundApiService.getFullUrl(item.userAvatar);
                                }
                                
                                String cacheBustedUrl(String url) {
                                  if (url.contains('?')) return '$url&v=${DateTime.now().millisecondsSinceEpoch}';
                                  return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
                                }

                                if (fullAvatarUrl != null) {
                                  return CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.transparent,
                                    backgroundImage: NetworkImage(cacheBustedUrl(fullAvatarUrl)),
                                  );
                                }

                                Widget gradientFallback() {
                                  return CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.transparent,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [Colors.cyan.shade300, Colors.purple.shade400],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        initial,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                if (item.userId != null && item.userId!.isNotEmpty) {
                                  return FutureBuilder<Map<String, dynamic>?>(
                                    future: UserApiService.getUserByIdCached(item.userId!),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.transparent,
                                          child: SizedBox(
                                            width: 24, height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2)
                                          ),
                                        );
                                      }
                                      String? fetchedPhoto;
                                      if (snapshot.hasData && snapshot.data != null) {
                                        final data = snapshot.data!;
                                        fetchedPhoto = data['photo']?.toString() ?? data['photo_url']?.toString() ?? data['avatar']?.toString() ?? data['profile_picture']?.toString();
                                        if (fetchedPhoto != null && fetchedPhoto.isNotEmpty) {
                                          fetchedPhoto = fetchedPhoto.startsWith('http') ? fetchedPhoto : LostFoundApiService.getFullUrl(fetchedPhoto);
                                        }
                                      }
                                      if (fetchedPhoto != null && fetchedPhoto.isNotEmpty) {
                                        return CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.transparent,
                                          backgroundImage: NetworkImage(cacheBustedUrl(fetchedPhoto)),
                                        );
                                      }
                                      return gradientFallback();
                                    },
                                  );
                                }

                                return gradientFallback();
                              }
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.userName ?? 'Mahasiswa',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "Pelapor Barang",
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF3D5AFE)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Deskripsi
                        const Text(
                          "Deskripsi Barang",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.description,
                          style: TextStyle(
                            fontSize: 15, 
                            color: Colors.grey.shade800, 
                            height: 1.6,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 100), // Space for bottom button
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              // Action Hubungi
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3D5AFE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text(
              "HUBUNGI PELAPOR",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
