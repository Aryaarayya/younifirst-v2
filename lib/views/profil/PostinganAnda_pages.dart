import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:younifirst_app/models/Event_model.dart';
import 'package:younifirst_app/models/Teams_model.dart';
import 'package:younifirst_app/models/lost_found_model.dart';
import 'package:younifirst_app/viewmodels/event_viewmodel.dart';
import 'package:younifirst_app/viewmodels/team_viewmodel.dart';
import 'package:younifirst_app/viewmodels/barang_viewmodel.dart';
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:younifirst_app/views/event/EventDetail_pages.dart';
import 'package:younifirst_app/views/team/TeamDetail_pages.dart';
import 'package:younifirst_app/views/team/TeamChat_pages.dart';
import 'package:younifirst_app/views/barang/Barang_pages.dart'; // To show Lost and Found comments or detail

class PostinganAndaPage extends StatefulWidget {
  const PostinganAndaPage({super.key});

  @override
  State<PostinganAndaPage> createState() => _PostinganAndaPageState();
}

class _PostinganAndaPageState extends State<PostinganAndaPage> {
  // Tabs: 0 = Event, 1 = Tim, 2 = Lost and Found
  int _activeCategoryIndex = 0;
  // Sub-tabs: 0 = Dibuat, 1 = Disukai
  int _activeSubTabIndex = 0;

  bool _isSearchActive = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventViewModel>().fetchEvents();
      context.read<TeamViewModel>().fetchAllTeams();
      context.read<TeamViewModel>().fetchMyTeams();
      context.read<BarangViewModel>().fetchBarang();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = AuthService.loggedInUserId ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.chevron_left,
                  size: 32,
                  color: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.black87,
                ),
              ),
              if (_isSearchActive)
                Expanded(
                  child: Container(
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: "Cari postingan...",
                        hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey.shade500),
                        prefixIcon: Icon(Icons.search, size: 20, color: isDark ? Colors.grey[500] : Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear, size: 18, color: isDark ? Colors.grey[500] : Colors.grey),
                          onPressed: () {
                            setState(() {
                              _searchCtrl.clear();
                              _searchQuery = "";
                              _isSearchActive = false;
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),
                )
              else
                Text(
                  "Postingan Anda",
                  style: TextStyle(
                    color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (!_isSearchActive)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSearchActive = true;
                    });
                  },
                  icon: Icon(
                    Icons.search,
                    size: 26,
                    color: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.black87,
                  ),
                )
              else
                const SizedBox(width: 48), // Spacer to balance layout
            ],
          ),
        ),
      ),
      body: Consumer3<EventViewModel, TeamViewModel, BarangViewModel>(
        builder: (context, eventVM, teamVM, barangVM, child) {
          final bool isAnyLoading = eventVM.isLoading || teamVM.isLoadingAll || barangVM.isLoading;

          // 1. EVENT DATA
          final eventDibuat = eventVM.events.where((e) {
            final eCreatedBy = e.createdBy.trim().toLowerCase();
            final curId = currentUserId.trim().toLowerCase();
            return eCreatedBy.isNotEmpty && curId.isNotEmpty && eCreatedBy == curId;
          }).toList();
          final eventDisukai = eventVM.events.where((e) => e.isLiked).toList();

          // 2. TEAM DATA
          // Dibuat = tim yang dibuat/dimiliki oleh user login
          final teamDibuat = teamVM.allTeams.where((t) {
            final tCreatedBy = t.createdBy.trim().toLowerCase();
            final curId = currentUserId.trim().toLowerCase();
            return (tCreatedBy.isNotEmpty && curId.isNotEmpty && tCreatedBy == curId) || t.isOwner;
          }).toList();
          // Diikuti = tim yang diikuti (user adalah member dan bukan owner)
          final teamDiikuti = teamVM.allTeams.where((t) => t.isMember && !t.isOwner).toList();

          // 3. LOST & FOUND DATA
          // Dibuat = barang yang diupload oleh user login
          final userBarang = barangVM.allData.where((lf) {
            final lfUserId = (lf.userId ?? '').trim().toLowerCase();
            final curId = currentUserId.trim().toLowerCase();
            return lfUserId.isNotEmpty && curId.isNotEmpty && lfUserId == curId;
          }).toList();

          final barangHilang = userBarang.where((b) => b.type.toLowerCase() == 'hilang' && !b.isCompleted).toList();
          final barangDitemukan = userBarang.where((b) => b.type.toLowerCase() == 'ditemukan' && !b.isCompleted).toList();
          final barangSelesai = userBarang.where((b) => b.isCompleted || b.type.toLowerCase() == 'diklaim').toList();

          // APPLY SEARCH FILTER IF SEARCH IS ACTIVE
          List<EventModel> filteredEvents = _activeSubTabIndex == 0 ? eventDibuat : eventDisukai;
          List<TeamModel> filteredTeams = _activeSubTabIndex == 0 ? teamDibuat : teamDiikuti;
          List<LostFoundModel> filteredBarang = [];
          if (_activeCategoryIndex == 2) {
            if (_activeSubTabIndex == 0) filteredBarang = barangHilang;
            else if (_activeSubTabIndex == 1) filteredBarang = barangDitemukan;
            else if (_activeSubTabIndex == 2) filteredBarang = barangSelesai;
            else filteredBarang = barangHilang;
          }

          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            filteredEvents = filteredEvents.where((e) => e.title.toLowerCase().contains(q) || e.location.toLowerCase().contains(q)).toList();
            filteredTeams = filteredTeams.where((t) => t.name.toLowerCase().contains(q) || t.lombaName.toLowerCase().contains(q)).toList();
            filteredBarang = filteredBarang.where((b) => b.itemName.toLowerCase().contains(q) || b.location.toLowerCase().contains(q)).toList();
          }

          // Dynamic Counts for top tabs
          int eventTotal = eventDibuat.length + eventDisukai.length;
          int teamTotal = teamDibuat.length + teamDiikuti.length;
          int barangTotal = userBarang.length;

          // Dynamic Counts for sub-tabs (based on currently active top tab)
          int subTabDibuatCount = 0;
          int subTabDisukaiCount = 0;
          if (_activeCategoryIndex == 0) {
            subTabDibuatCount = eventDibuat.length;
            subTabDisukaiCount = eventDisukai.length;
          } else if (_activeCategoryIndex == 1) {
            subTabDibuatCount = teamDibuat.length;
            subTabDisukaiCount = teamDiikuti.length;
          }

          return Column(
            children: [
              // Top Category Tabs
              Container(
                color: Theme.of(context).appBarTheme.backgroundColor,
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildCategoryTab(0, "Event", Icons.calendar_today_outlined, eventTotal),
                        _buildCategoryTab(1, "Tim", Icons.group_outlined, teamTotal),
                        _buildCategoryTab(2, "Lost and Found", Icons.search_outlined, barangTotal),
                      ],
                    ),
                    Divider(height: 1, thickness: 1, color: Theme.of(context).dividerColor),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sub-tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _activeCategoryIndex == 2
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildSubTab(0, "Hilang", Icons.inbox_outlined, barangHilang.length),
                            const SizedBox(width: 12),
                            _buildSubTab(1, "Ditemukan", Icons.inbox_outlined, barangDitemukan.length),
                            const SizedBox(width: 12),
                            _buildSubTab(2, "Selesai", Icons.check_circle_outline, barangSelesai.length),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          _buildSubTab(0, "Dibuat", Icons.copy_all_outlined, subTabDibuatCount),
                          const SizedBox(width: 12),
                          _buildSubTab(
                            1,
                            _activeCategoryIndex == 1 ? "Diikuti" : "Disukai",
                            _activeCategoryIndex == 1 ? Icons.people_outline : Icons.favorite_border,
                            subTabDisukaiCount,
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 20),

              // Card Listings or skeletons
              Expanded(
                child: isAnyLoading
                    ? (_activeCategoryIndex == 1 ? _buildTeamSkeletonList() : _buildSkeletonGrid())
                    : _activeCategoryIndex == 0
                        ? _buildEventGrid(filteredEvents, eventVM)
                        : _activeCategoryIndex == 1
                            ? _buildTeamGrid(filteredTeams, teamVM)
                            : _buildBarangGrid(filteredBarang, barangVM),
              ),
            ],
          );
        },
      ),
    );
  }

  // CATEGORY TABS
  Widget _buildCategoryTab(int index, String title, IconData icon, int count) {
    bool isActive = _activeCategoryIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_activeCategoryIndex != index) {
              _activeSubTabIndex = 0; // Reset sub-tab
            }
            _activeCategoryIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFF3D5AFE) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isActive ? const Color(0xFF3D5AFE) : (isDark ? Colors.grey[400] : Colors.grey.shade600),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      "$title ($count)",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? const Color(0xFF3D5AFE) : (isDark ? Colors.grey[400] : Colors.grey.shade600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // SUB-TABS (Dibuat, Disukai)
  Widget _buildSubTab(int index, String title, IconData icon, int count) {
    bool isActive = _activeSubTabIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeSubTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF3D5AFE) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFF3D5AFE),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF3D5AFE).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : const Color(0xFF3D5AFE),
            ),
            const SizedBox(width: 6),
            Text(
              "$title ($count)",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : const Color(0xFF3D5AFE),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // SKELETON PLACEHOLDER LOADING STATE
  Widget _buildSkeletonGrid() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDark ? const Color(0xFF242424) : const Color(0xFFE2E8F0);
    final skeletonLineColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9);

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: 100, color: skeletonColor),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(height: 10, width: 10, color: skeletonColor),
                        const SizedBox(width: 6),
                        Container(height: 8, width: 60, color: skeletonColor),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(height: 10, width: 10, color: skeletonColor),
                        const SizedBox(width: 6),
                        Container(height: 8, width: 40, color: skeletonColor),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(height: 1, width: double.infinity, color: skeletonLineColor),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(height: 16, width: 16, color: skeletonColor),
                            const SizedBox(width: 4),
                            Container(height: 10, width: 12, color: skeletonColor),
                          ],
                        ),
                        Container(
                          height: 28,
                          width: 50,
                          decoration: BoxDecoration(
                            color: skeletonColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // EVENT GRID
  Widget _buildEventGrid(List<EventModel> events, EventViewModel viewModel) {
    if (events.isEmpty) {
      return _buildEmptyState("Belum ada postingan event.");
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final ev = events[index];
        bool isNetworkImage = ev.imageUrl.toLowerCase().startsWith('http');

        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailPage(eventId: ev.id),
              ),
            );
            if (result == true) {
              viewModel.fetchEvents();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 110,
                      width: double.infinity,
                      color: isDark ? const Color(0xFF242424) : Colors.grey[200],
                      child: isNetworkImage
                          ? Image.network(
                              ev.imageUrl,
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
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ev.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 12, color: Color(0xFF3D5AFE)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ev.date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.black54,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF3D5AFE)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ev.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.black54,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(color: Theme.of(context).dividerColor, thickness: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => viewModel.toggleLike(ev.id),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                  child: Icon(
                                    ev.isLiked ? Icons.favorite : Icons.favorite_border,
                                    key: ValueKey(ev.isLiked),
                                    size: 18,
                                    color: ev.isLiked ? Colors.redAccent : (isDark ? Colors.grey[400] : Colors.black.withOpacity(0.6)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                ev.likesCount,
                                style: TextStyle(
                                  color: isDark ? Colors.grey[300] : Colors.black.withOpacity(0.7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3D5AFE),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: const [
                                Text(
                                  "Mulai",
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 10),
                              ],
                            ),
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
      },
    );
  }

  // SKELETON PLACEHOLDER LOADING STATE FOR TEAMS
  Widget _buildTeamSkeletonList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDark ? const Color(0xFF242424) : const Color(0xFFE2E8F0);
    final skeletonLineColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(color: skeletonLineColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon placeholder
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14, width: 120, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(height: 10, width: 10, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 6),
                            Container(height: 8, width: 80, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(2))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(height: 8, width: double.infinity, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(height: 6),
                        Container(height: 8, width: 150, decoration: BoxDecoration(color: skeletonColor, borderRadius: BorderRadius.circular(2))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Pills placeholders
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        height: 18,
                        width: 40,
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 18,
                        width: 30,
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Button placeholder
              Container(
                height: 40,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: skeletonColor,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // TEAM GRID
  Widget _buildTeamGrid(List<TeamModel> teams, TeamViewModel viewModel) {
    if (teams.isEmpty) {
      return _buildEmptyState("Belum ada postingan tim.");
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: teams.length,
      itemBuilder: (context, index) {
        return _buildTeamCard(teams[index], viewModel);
      },
    );
  }

  Widget _buildTeamCard(TeamModel t, TeamViewModel viewModel) {
    int maxMm = t.maxMembers > 0 ? t.maxMembers : 4;
    String displayStatus = t.status;
    if (t.status.toLowerCase() == 'approved' || t.status.toLowerCase() == 'open') {
      displayStatus = t.joinedMembers < maxMm ? 'Open' : 'Full';
    }

    final isFull = displayStatus.toLowerCase() == 'full';
    final isChatAvailable = t.isOwner || t.isAcceptedMember;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamDetailPage(teamId: t.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2138) : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.groups_outlined,
                        color: Color(0xFF3D5AFE),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.arrow_forward,
                                size: 14,
                                color: Color(0xFF3D5AFE),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  t.lombaName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF3D5AFE),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[400] : Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isFull ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isFull ? "Full" : "Open",
                            style: TextStyle(
                              color: isFull ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${t.joinedMembers}/$maxMm",
                            style: const TextStyle(
                              color: Color(0xFF3D5AFE),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isChatAvailable) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeamChatPage(teamId: t.id, teamName: t.name),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3D5AFE), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        backgroundColor: Theme.of(context).cardColor,
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Buka Chat Tim',
                            style: TextStyle(
                              color: Color(0xFF3D5AFE),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.chat_bubble,
                            color: Color(0xFF3D5AFE),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // LOST & FOUND GRID
  Widget _buildBarangGrid(List<LostFoundModel> barangList, BarangViewModel viewModel) {
    if (barangList.isEmpty) {
      return _buildEmptyState(
        "Belum ada postingan",
        "Kamu belum membuat postingan\napapun mengenai ini.",
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.68,
      ),
      itemCount: barangList.length,
      itemBuilder: (context, index) {
        final b = barangList[index];
        bool isDitemukan = b.type == 'Ditemukan';

        return GestureDetector(
          onTap: () {
            // Navigate to main Lost and Found page with details (or trigger detail if there is one)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BarangPage(), // Main Lost and Found Page
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF242424) : Colors.grey[200],
                      child: b.imageUrl != null && b.imageUrl!.isNotEmpty
                          ? Image.network(
                              b.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, color: Colors.grey),
                            )
                          : const Icon(Icons.image, color: Colors.grey, size: 30),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDitemukan ? const Color(0xFF3D5AFE).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              b.type,
                              style: TextStyle(
                                color: isDitemukan ? const Color(0xFF3D5AFE) : Colors.red,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (b.isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                "Selesai",
                                style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        b.itemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 10, color: Color(0xFF3D5AFE)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              b.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 14, color: Theme.of(context).dividerColor),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 12,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                b.commentsCount.toString(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3D5AFE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.chevron_right, color: Colors.white, size: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // EMPTY STATE HELPER
  Widget _buildEmptyState(String title, [String? subtitle]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool hasSubtitle = subtitle != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSubtitle ? Icons.manage_search_rounded : Icons.feed_outlined, 
              size: hasSubtitle ? 100 : 64, 
              color: hasSubtitle ? const Color(0xFF3D5AFE) : Colors.grey.shade300
            ),
            SizedBox(height: hasSubtitle ? 24 : 16),
            Text(
              title,
              style: hasSubtitle 
                ? TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  )
                : TextStyle(
                    color: Colors.grey.shade500, 
                    fontSize: 15, 
                    fontWeight: FontWeight.w500
                  ),
              textAlign: TextAlign.center,
            ),
            if (hasSubtitle) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
