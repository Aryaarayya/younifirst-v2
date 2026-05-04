import 'package:flutter/material.dart';
import 'package:younifirst_app/pages/team/TambahTeams_pages.dart';
import 'package:younifirst_app/models/Teams_model.dart';
import 'package:younifirst_app/services/team_api_service.dart';
import 'package:younifirst_app/services/auth_service.dart';
import 'package:younifirst_app/widgets/notification_bell.dart';
import 'package:younifirst_app/pages/team/MyTeams_pages.dart';
import 'package:younifirst_app/pages/team/TeamDetail_pages.dart';
import 'package:younifirst_app/pages/team/TeamApplications_pages.dart';
import 'package:younifirst_app/pages/team/TeamChat_pages.dart';
import 'package:younifirst_app/pages/team/GlobalTeamApplications_pages.dart';
class TeamsPage extends StatefulWidget {
  @override
  _TeamsPageState createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  List<TeamModel> teams = [];
  bool isLoading = true;
  String errorMessage = "";
  String _searchQuery = "";
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTeams();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchTeams() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      final fetchedTeams = await TeamApiService.getTeams();
      setState(() {
        teams = fetchedTeams;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
        isLoading = false;
      });
      debugPrint("Fetch Error: $e");
    }
  }

  List<TeamModel> get _filteredTeams {
    if (_searchQuery.isEmpty) return teams;
    final q = _searchQuery.toLowerCase();
    return teams
        .where((t) =>
            t.name.toLowerCase().contains(q) ||
            t.lombaName.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SingleChildScrollView(
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
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildShortcutCards(),
                  const SizedBox(height: 16),
                  _buildTeamList(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TambahTeamsPage()),
          );
          if (result == true) fetchTeams();
        },
        backgroundColor: const Color(0xFF3D5AFE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
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
                "Team",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          NotificationBell(iconColor: Colors.white),
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
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Mulai cari tim...",
                  hintStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.description, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Icon(Icons.menu, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  // ─── Shortcut Cards (Tim Saya & Lamaran Masuk) ────────────────────────────
  Widget _buildShortcutCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _shortcutItem(
                  icon: Icons.groups_outlined,
                  title: 'Tim Saya',
                  subtitle: 'Lihat semua tim yang\nkamu ikuti',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyTeamsPage()),
                  ),
                ),
              ),
              VerticalDivider(
                color: Colors.grey.shade200,
                width: 1,
                thickness: 1,
                indent: 12,
                endIndent: 12,
              ),
              Expanded(
                child: _shortcutItem(
                  icon: Icons.assignment_ind_outlined,
                  title: 'Lamaran Masuk',
                  subtitle: 'Lihat pendaftar di tim\nyang kamu buat',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GlobalTeamApplicationsPage()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shortcutItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF3D5AFE), size: 22),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.black54),
                      maxLines: 2),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54, size: 16),
          ],
        ),
      ),
    );
  }

  // ─── Team List ────────────────────────────────────────────────────────────
  Widget _buildTeamList() {
    if (isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
            child: Text(errorMessage,
                style: const TextStyle(color: Colors.red))),
      );
    }

    final filtered = _filteredTeams;

    if (filtered.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
            child: Text("Belum ada tim.",
                style: TextStyle(color: Colors.black54))),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: RefreshIndicator(
        onRefresh: fetchTeams,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final t = filtered[index];
            final uid = AuthService.loggedInUserId;
            final isOwner = uid != null && t.createdBy == uid;
            int maxMm = t.maxMembers > 0 ? t.maxMembers : 4;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _teamCard(t, isOwner, maxMm),
            );
          },
        ),
      ),
    );
  }

  Widget _teamCard(TeamModel t, bool isOwner, int maxMm) {
    String displayStatus = t.status;
    if (t.status.toLowerCase() == 'approved') {
      displayStatus = t.joinedMembers < maxMm ? 'Open' : 'Full';
    }
    
    final isOpen = displayStatus.toLowerCase() == 'open';
    final isPending = displayStatus.toLowerCase() == 'pending';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TeamDetailPage(teamId: t.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER CARD
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.groups_outlined,
                          color: Color(0xFF3D5AFE), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                _statusBadge(displayStatus, isOpen, isPending),
              ],
            ),
            const SizedBox(height: 12),

            // Lomba
            Row(
              children: [
                const Icon(Icons.arrow_forward, size: 18, color: Color(0xFF3D5AFE)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t.lombaName,
                    style: const TextStyle(
                        color: Color(0xFF3D5AFE),
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Desc
            Text(
              t.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),

            // Member avatars + count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    t.joinedMembers.clamp(0, 4),
                    (i) => Align(
                      widthFactor: 0.7,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.grey[300],
                          child: t.memberNames.length > i
                              ? Text(
                                  t.memberNames[i][0].toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  "${t.joinedMembers}/$maxMm Anggota",
                  style: const TextStyle(
                      color: Color(0xFF3D5AFE),
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status, bool isOpen, bool isPending) {
    final s = status.toLowerCase();
    Color bg;
    Color fg;
    if (s == 'open') {
      bg = Colors.green.shade100;
      fg = Colors.green.shade700;
    } else if (isPending) {
      bg = Colors.orange.shade100;
      fg = Colors.orange.shade800;
    } else if (s == 'full') {
      bg = Colors.red.shade100;
      fg = Colors.red.shade700;
    } else {
      bg = Colors.red.shade100;
      fg = Colors.red.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status,
        style: TextStyle(
            color: fg, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}