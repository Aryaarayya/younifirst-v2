import 'package:younifirst_app/services/api/event_api_service.dart';
import 'package:younifirst_app/services/api/user_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:younifirst_app/models/Event_model.dart';
import 'package:younifirst_app/models/lost_found_model.dart';
import 'package:younifirst_app/models/Teams_model.dart';
import 'package:younifirst_app/models/comment_model.dart';
import 'package:younifirst_app/services/api/lostandfound_api_service.dart';
import 'package:younifirst_app/services/api/team_api_service.dart';
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:younifirst_app/services/input/notification_service.dart';
import 'package:younifirst_app/utils/profanity_filter.dart';
import 'package:younifirst_app/views/barang/BarangDetail_pages.dart';
import 'package:younifirst_app/views/barang/EditBarang_pages.dart';
import 'package:younifirst_app/widgets/notification_bell.dart';
import 'package:provider/provider.dart';
import 'package:younifirst_app/viewmodels/profil_viewmodel.dart';
import 'package:younifirst_app/viewmodels/barang_viewmodel.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<LostFoundModel> _lostFoundItems = [];
  List<EventModel> _events = [];
  List<TeamModel> _teams = [];
  bool _isLoading = true;
  String _selectedFilter = "Untuk Anda";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _expandedDescriptions = {};

  final List<String> _commonEmojis = [
    '😀', '😂', '😍', '🤣', '😊', '🙏', '😭', '😘', '👍', '✨', 
    '🔥', '🥰', '👏', '🤔', '🙌', '🎉', '😎', '🤩', '💡', '📍',
    '📢', '📦', '🔑', '🎒', '📱', '⌚', '💳', '📄', '🚲', '👟'
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        LostFoundApiService.getLostAndFound(),
        EventApiService.getEvents(),
        TeamApiService.getTeams(),
      ]);

      setState(() {
        _lostFoundItems = results[0] as List<LostFoundModel>;
        _events = results[1] as List<EventModel>;
        _teams = results[2] as List<TeamModel>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching home data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer<ProfilViewModel>(
      builder: (context, profilViewModel, child) {
        final _userProfileData = profilViewModel.userData;
        final String userName = _userProfileData?['name'] ?? 'User';
        final String userAvatar = (_userProfileData?['photo'] != null && _userProfileData!['photo'].toString().isNotEmpty)
            ? '${LostFoundApiService.getFullUrl(_userProfileData['photo'])}?v=${DateTime.now().millisecondsSinceEpoch}'
            : '';

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: RefreshIndicator(
            onRefresh: () async {
              await profilViewModel.fetchUserData();
              await _fetchData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Stack(
                children: [
                  Container(
                    height: 320,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3D5AFE),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(userName, userAvatar),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildFilterChips(),
                    const SizedBox(height: 16),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: _buildFilteredContent(),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
}

  Widget _buildHeader(String name, String avatar) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: avatar.isNotEmpty 
                  ? Image.network(
                      avatar,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const CircleAvatar(radius: 25, child: Icon(Icons.person)),
                    )
                  : const CircleAvatar(radius: 25, child: Icon(Icons.person)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Selamat datang kembali👋",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const NotificationBell(iconColor: Colors.white),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Mulai cari...",
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(CupertinoIcons.search, color: Colors.white),
                  suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = "";
                          });
                        },
                      )
                    : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 45,
            width: 45,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_alt_outlined, color: Colors.white),
              onPressed: () {
                _showFilterBottomSheet(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip("Untuk Anda", _selectedFilter == "Untuk Anda", icon: Icons.check_circle),
            const SizedBox(width: 12),
            _filterChip("Postingan Terbaru", _selectedFilter == "Postingan Terbaru", icon: Icons.new_releases),
            if (_selectedFilter != "Untuk Anda" && _selectedFilter != "Postingan Terbaru") ...[
              const SizedBox(width: 12),
              _filterChip(_selectedFilter, true, icon: _getIconForFilter(_selectedFilter)),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForFilter(String filter) {
    switch (filter) {
      case "Untuk Anda": return Icons.check_circle;
      case "Postingan Terbaru": return Icons.new_releases;
      case "Event": return Icons.calendar_today;
      case "Tim": return Icons.people;
      case "Lost and Found": return Icons.search;
      default: return Icons.filter_list;
    }
  }

  Widget _filterChip(String label, bool active, {IconData? icon}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          border: active ? null : Border.all(color: Colors.white.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: active ? const Color(0xFF3D5AFE) : Colors.white,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFF3D5AFE) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    String tempSelected = _selectedFilter;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Filter",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _modalFilterChip("Untuk Anda", tempSelected == "Untuk Anda", Icons.check_circle, () {
                        setModalState(() => tempSelected = "Untuk Anda");
                      }),
                      _modalFilterChip("Postingan Terbaru", tempSelected == "Postingan Terbaru", Icons.new_releases, () {
                        setModalState(() => tempSelected = "Postingan Terbaru");
                      }),
                      _modalFilterChip("Event", tempSelected == "Event", Icons.calendar_today, () {
                        setModalState(() => tempSelected = "Event");
                      }),
                      _modalFilterChip("Tim", tempSelected == "Tim", Icons.people, () {
                        setModalState(() => tempSelected = "Tim");
                      }),
                      _modalFilterChip("Lost and Found", tempSelected == "Lost and Found", Icons.search, () {
                        setModalState(() => tempSelected = "Lost and Found");
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() => tempSelected = "Untuk Anda");
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE3F2FD)),
                            backgroundColor: const Color(0xFFE3F2FD),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("Reset", style: TextStyle(color: Color(0xFF3D5AFE), fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = tempSelected;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D5AFE),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text("Terapkan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _modalFilterChip(String label, bool active, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF3D5AFE) : Theme.of(context).cardColor,
          border: Border.all(color: active ? const Color(0xFF3D5AFE) : const Color(0xFF3D5AFE).withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? Colors.white : const Color(0xFF3D5AFE),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF3D5AFE),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredContent() {
    switch (_selectedFilter) {
      case "Event":
        return _buildEventListOnly();
      case "Tim":
        return _buildTeamListOnly();
      case "Lost and Found":
        return _buildLostFoundListOnly();
      case "Postingan Terbaru":
        return _buildLostFoundListOnly(); 
      default:
        return _buildDefaultFeed();
    }
  }

  Widget _buildDefaultFeed() {
    final filteredLostFound = _lostFoundItems.where((item) {
      return item.itemName.toLowerCase().contains(_searchQuery) ||
             item.description.toLowerCase().contains(_searchQuery) ||
             item.location.toLowerCase().contains(_searchQuery);
    }).toList();

    final filteredEvents = _events.where((event) {
      return event.title.toLowerCase().contains(_searchQuery) ||
             event.location.toLowerCase().contains(_searchQuery);
    }).toList();

    return Column(
      children: [
        if (filteredLostFound.isEmpty && _searchQuery.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text("Tidak ada hasil pencarian"),
          )
        else if (filteredLostFound.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text("Belum ada postingan terbaru"),
          )
        else
          ...filteredLostFound.take(2).map((item) => _buildFeedCardFromModel(item)),

        if (filteredEvents.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchQuery.isEmpty ? "Popular Events 🔥" : "Events Relevan",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedFilter = "Event");
                  },
                  child: const Text(
                    "LIHAT SEMUA",
                    style: TextStyle(
                      color: Color(0xFF3D5AFE),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildFilteredEventsHorizontalList(filteredEvents),
          const SizedBox(height: 20),
        ],

        if (filteredLostFound.length > 2)
          ...filteredLostFound.skip(2).map((item) => _buildFeedCardFromModel(item)),

        const SizedBox(height: 100), 
      ],
    );
  }

  Widget _buildFilteredEventsHorizontalList(List<EventModel> filtered) {
    return SizedBox(
      height: 270,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final event = filtered[index];
          return _buildMiniEventCard(event);
        },
      ),
    );
  }

  Widget _buildEventListOnly() {
    final filtered = _events.where((event) {
      return event.title.toLowerCase().contains(_searchQuery) ||
             event.location.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(_searchQuery.isEmpty ? "Tidak ada event ditemukan" : "Tidak ada event yang cocok dengan '$_searchQuery'")));
    }
    return Column(
      children: filtered.map<Widget>((event) => _buildFullWidthEventCard(event)).toList() + [const SizedBox(height: 100)],
    );
  }

  Widget _buildTeamListOnly() {
    final filtered = _teams.where((team) {
      return team.name.toLowerCase().contains(_searchQuery) ||
             team.lombaName.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(_searchQuery.isEmpty ? "Tidak ada tim ditemukan" : "Tidak ada tim yang cocok dengan '$_searchQuery'")));
    }
    return Column(
      children: filtered.map<Widget>((team) => _buildTeamCard(team)).toList() + [const SizedBox(height: 100)],
    );
  }

  Widget _buildLostFoundListOnly() {
    final filtered = _lostFoundItems.where((item) {
      return item.itemName.toLowerCase().contains(_searchQuery) ||
             item.description.toLowerCase().contains(_searchQuery) ||
             item.location.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(_searchQuery.isEmpty ? "Tidak ada postingan ditemukan" : "Tidak ada postingan yang cocok dengan '$_searchQuery'")));
    }
    return Column(
      children: filtered.map<Widget>((item) => _buildFeedCardFromModel(item)).toList() + [const SizedBox(height: 100)],
    );
  }

  Widget _buildFeedCardFromModel(LostFoundModel item) {
    bool isDitemukan = item.type == 'Ditemukan' || item.type == 'Diklaim';

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: (item.userAvatar != null && item.userAvatar!.isNotEmpty)
                  ? Image.network(
                      item.userAvatar!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 20)),
                    )
                  : const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 20)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      _formatDate(item.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.grey),
                onSelected: (value) async {
                  if (value == 'edit') {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditBarangPage(item: item)),
                    );
                    if (result == true) _fetchData();
                  } else if (value == 'finish') {
                    _showFinishConfirmation(context, item);
                  } else if (value == 'report') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan telah dikirim')));
                  }
                },
                itemBuilder: (context) {
                  bool isOwner = item.userId == AuthService.loggedInUserId;
                  return [
                    if (isOwner) ...[
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit Postingan')]),
                      ),
                      const PopupMenuItem(
                        value: 'finish',
                        child: Row(children: [Icon(Icons.check_circle_outline, size: 20), SizedBox(width: 8), Text('Selesaikan')]),
                      ),
                    ] else ...[
                      const PopupMenuItem(
                        value: 'report',
                        child: Row(children: [Icon(Icons.report_gmailerrorred, size: 20, color: Colors.red), SizedBox(width: 8), Text('Laporkan', style: TextStyle(color: Colors.red))]),
                      ),
                    ]
                  ];
                },
              ),
            ],
          ),
          
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.imageUrl!,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(height: 300, color: Colors.grey[200]),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D5AFE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.type,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                ),
              ],
            )
          else 
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D5AFE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.type,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ),
            
          const SizedBox(height: 16),
          Text(
            item.itemName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Color(0xFF3D5AFE)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.location,
                  style: const TextStyle(color: Color(0xFF3D5AFE), fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Builder(
            builder: (context) {
              bool isExpanded = _expandedDescriptions.contains(item.lostfoundId);
              bool isLong = item.description.length > 150;
              String displayDesc = (isLong && !isExpanded) 
                  ? '${item.description.substring(0, 150)}...' 
                  : item.description;

              return GestureDetector(
                onTap: () {
                  if (isLong) {
                    setState(() {
                      if (isExpanded) _expandedDescriptions.remove(item.lostfoundId);
                      else _expandedDescriptions.add(item.lostfoundId);
                    });
                  }
                },
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.4),
                    children: [
                      TextSpan(text: '$displayDesc '),
                      if (isLong)
                        TextSpan(
                          text: isExpanded ? 'lebih sedikit' : 'selengkapnya...',
                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: () {
              _showCommentSheet(context, item.lostfoundId);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Text("Beri Komentar...", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const Spacer(),
                  const Icon(CupertinoIcons.chat_bubble, size: 18, color: Colors.grey),
                  if (item.commentsCount > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      "${item.commentsCount}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ]
                ],
              ),
            ),
          ),
          
          if (!item.isCompleted && item.userId == AuthService.loggedInUserId) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _showFinishConfirmation(context, item);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3D5AFE)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: const Color(0xFFEEF2FF),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Tandai Postingan Selesai', style: TextStyle(color: Color(0xFF3D5AFE), fontWeight: FontWeight.bold)),
              ),
            )
          ]
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "Baru saja";
    try {
      DateTime dt = DateTime.parse(dateStr);
      Duration diff = DateTime.now().difference(dt);
      if (diff.inDays >= 1) return "${diff.inDays} hari lalu";
      if (diff.inHours >= 1) return "${diff.inHours} jam lalu";
      if (diff.inMinutes >= 1) return "${diff.inMinutes} mnt lalu";
      return "Baru saja";
    } catch (e) {
      return dateStr;
    }
  }

  void _showCommentSheet(BuildContext context, String lostFoundId) {
    TextEditingController commentController = TextEditingController();
    bool isSending = false;
    CommentModel? replyingTo;
    CommentModel? editingComment;
    Set<String> expandedCommentIds = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Komentar postingan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  Expanded(
                    child: FutureBuilder<List<CommentModel>>(
                      future: LostFoundApiService.getComments(lostFoundId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) return Center(child: Text('Gagal: ${snapshot.error}'));
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildEmptyComments();
                        }

                        final allComments = snapshot.data!;
                        final Map<String, CommentModel> commentMap = {for (var c in allComments) c.id: c};
                        final List<CommentModel> rootComments = [];
                        
                        for (var c in allComments) {
                          if (c.parentId != null && commentMap.containsKey(c.parentId)) {
                            commentMap[c.parentId]!.replies.add(c);
                          } else {
                            rootComments.add(c);
                          }
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: rootComments.length,
                          itemBuilder: (context, index) {
                            return _buildThreadedComment(
                              rootComments[index], 
                              setModalState,
                              expandedCommentIds,
                              () => setModalState(() {}),
                              (comment) {
                                setModalState(() {
                                  replyingTo = comment;
                                  editingComment = null;
                                  commentController.text = "";
                                });
                              },
                              (comment) {
                                setModalState(() {
                                  editingComment = comment;
                                  replyingTo = null;
                                  commentController.text = comment.commentTextOnly;
                                });
                              }
                            );
                          },
                        );
                      },
                    ),
                  ),

                  _buildCommentInput(
                    commentController, 
                    isSending, 
                    replyingTo, 
                    editingComment,
                    () => setModalState(() { replyingTo = null; editingComment = null; commentController.clear(); }),
                    () async {
                      if (commentController.text.trim().isEmpty) return;
                      List<String> badWords = ProfanityFilter.check(commentController.text);
                      if (badWords.isNotEmpty) {
                        _showProfanityWarning(context, badWords);
                        return;
                      }

                      setModalState(() => isSending = true);
                      try {
                        bool success;
                        if (editingComment != null) {
                          success = await LostFoundApiService.updateComment(editingComment!.id, commentController.text);
                        } else {
                          success = await LostFoundApiService.addComment(lostFoundId, commentController.text, parentId: replyingTo?.id);
                        }

                        if (success) {
                          await NotificationService.addNotification(
                            editingComment != null ? 'Komentar Diperbarui' : 'Komentar Berhasil', 
                            editingComment != null ? 'Anda telah memperbarui komentar.' : 'Anda telah mengomentari postingan.',
                            type: 'comment',
                            targetId: lostFoundId
                          );
                          commentController.clear();
                          setModalState(() {
                            isSending = false;
                            replyingTo = null;
                            editingComment = null;
                          });
                          _fetchData(); 
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                        setModalState(() => isSending = false);
                      }
                    }
                  ),
                ],
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildEmptyComments() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("Belum ada komentar", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildThreadedComment(
    CommentModel comment, 
    StateSetter setModalState,
    Set<String> expandedIds,
    VoidCallback onRefresh,
    Function(CommentModel) onReply,
    Function(CommentModel) onEdit,
  ) {
    bool hasReplies = comment.replies.isNotEmpty;
    bool isExpanded = expandedIds.contains(comment.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentItem(comment, false, onRefresh, onReply, onEdit),
        if (hasReplies) ...[
          Padding(
            padding: const EdgeInsets.only(left: 58, bottom: 8),
            child: InkWell(
              onTap: () => setModalState(() {
                if (isExpanded) expandedIds.remove(comment.id);
                else expandedIds.add(comment.id);
              }),
              child: Row(
                children: [
                  Container(width: 40, height: 1, color: Colors.grey.shade300),
                  const SizedBox(width: 12),
                  Text(
                    isExpanded ? "Sembunyikan balasan" : "Lihat balasan (${comment.replies.length})",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Column(
                children: comment.replies.map((reply) => _buildCommentItem(reply, true, onRefresh, onReply, onEdit)).toList(),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildCommentItem(
    CommentModel comment, 
    bool isReply, 
    VoidCallback onRefresh,
    Function(CommentModel) onReply,
    Function(CommentModel) onEdit,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 12 : 16,
            backgroundColor: const Color(0xFF3D5AFE),
            backgroundImage: comment.userAvatar != null ? NetworkImage(comment.userAvatar!) : null,
            child: comment.userAvatar == null 
              ? Text((comment.userName ?? 'U')[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: isReply ? 10 : 12))
              : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(comment.userName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 8),
                          Text(_formatDate(comment.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    _buildCommentMenu(comment, onEdit, onRefresh),
                  ],
                ),
                Text(comment.commentTextOnly, style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => onReply(comment),
                  child: Text("Balas", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentMenu(CommentModel comment, Function(CommentModel) onEdit, VoidCallback onRefresh) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
      onSelected: (value) async {
        if (value == 'edit') {
          onEdit(comment);
        } else if (value == 'delete') {
          try {
            await LostFoundApiService.deleteComment(comment.id);
            onRefresh();
          } catch (e) {
            debugPrint("Delete comment error: $e");
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
      ],
    );
  }

  Widget _buildCommentInput(
    TextEditingController controller, 
    bool isSending, 
    CommentModel? replyingTo,
    CommentModel? editingComment,
    VoidCallback onCancel,
    VoidCallback onSend,
  ) {
    bool isDirectAction = replyingTo != null || editingComment != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDirectAction)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(editingComment != null ? "Mengedit..." : "Membalas...", style: const TextStyle(fontSize: 11, color: Color(0xFF3D5AFE))),
                    const Spacer(),
                    GestureDetector(onTap: onCancel, child: const Icon(Icons.cancel, size: 16, color: Colors.grey)),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Tambahkan komentar...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      fillColor: Colors.grey.shade100,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send, color: Color(0xFF3D5AFE)),
                  onPressed: onSend,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFinishConfirmation(BuildContext context, LostFoundModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tandai Selesai?"),
        content: const Text("Postingan ini akan dihapus dari dashboard."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await LostFoundApiService.deleteLostFound(item.lostfoundId);
              _fetchData();
            }, 
            child: const Text("Ya, Selesai", style: TextStyle(color: Color(0xFF3D5AFE)))
          ),
        ],
      ),
    );
  }

  void _showProfanityWarning(BuildContext context, List<String> badWords) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Peringatan"),
        content: Text("Komentar mengandung kata tidak pantas: ${badWords.join(", ")}"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  Widget _buildTeamCard(TeamModel team) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: const Color(0xFF3D5AFE).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.people, color: Color(0xFF3D5AFE), size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(team.lombaName, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text("${team.joinedMembers} Anggota", style: const TextStyle(color: Color(0xFF3D5AFE), fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildMiniEventCard(EventModel event) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              child: Image.network(event.imageUrl, height: 130, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(height: 130, color: Colors.grey[200])),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87)),
                  const SizedBox(height: 8),
                  Row(children: [const Icon(Icons.calendar_today, size: 12, color: Color(0xFF3D5AFE)), const SizedBox(width: 4), Expanded(child: Text("${event.date} • ${event.time}", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54, fontSize: 10)))]),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.location_on_outlined, size: 12, color: Color(0xFF3D5AFE)), const SizedBox(width: 4), Expanded(child: Text(event.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54, fontSize: 10)))]),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [const Icon(CupertinoIcons.heart_fill, size: 16, color: Colors.redAccent), const SizedBox(width: 4), Text(event.likesCount, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))]),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFF3D5AFE), borderRadius: BorderRadius.circular(12)), child: const Row(children: [Text("Mulai", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)), SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12)])),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidthEventCard(EventModel event) {
    return _buildMiniEventCard(event);
  }

  Widget _buildEventsHorizontalList() {
    if (_events.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text("Tidak ada event terbaru"));
    return SizedBox(height: 290, child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _events.length, itemBuilder: (context, index) => _buildMiniEventCard(_events[index])));
  }
}
