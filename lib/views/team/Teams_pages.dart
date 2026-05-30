import 'package:flutter/material.dart';
import 'package:younifirst_app/views/team/TambahTeams_pages.dart';
import 'package:younifirst_app/models/Teams_model.dart';
import 'package:younifirst_app/services/api/team_api_service.dart';
import 'package:younifirst_app/services/api/user_api_service.dart';
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:younifirst_app/widgets/notification_bell.dart';
import 'package:younifirst_app/views/team/MyTeams_pages.dart';
import 'package:younifirst_app/views/team/TeamDetail_pages.dart';
import 'package:younifirst_app/views/team/TeamApplications_pages.dart';
import 'package:younifirst_app/views/team/TeamChat_pages.dart';
import 'package:younifirst_app/views/team/GlobalTeamApplications_pages.dart';
import 'package:provider/provider.dart';
import 'package:younifirst_app/viewmodels/team_viewmodel.dart';
class TeamsPage extends StatefulWidget {
  @override
  _TeamsPageState createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamViewModel>().fetchAllTeams();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<TeamViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            child: Stack(
              children: [
                // Blue Background Top
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF121212)
                        : const Color(0xFF3D5AFE),
                  ),
                ),
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildSearchBar(viewModel),
                      const SizedBox(height: 16),
                      _buildShortcutCards(),
                      const SizedBox(height: 16),
                      _buildTeamList(viewModel),
                      const SizedBox(height: 80),
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
            MaterialPageRoute(builder: (context) => TambahTeamsPage()),
          );
          if (result == true) context.read<TeamViewModel>().fetchAllTeams();
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

  Widget _buildSearchBar(TeamViewModel viewModel) {
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
                onChanged: (v) => viewModel.setSearchQuery(v),
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
          color: Theme.of(context).cardColor,
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
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3D5AFE).withOpacity(0.2)
                    : const Color(0xFFEEF2FF),
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
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87)),
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
  Widget _buildTeamList(TeamViewModel viewModel) {
    if (viewModel.isLoadingAll) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (viewModel.errorAll.isNotEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
            child: Text(viewModel.errorAll,
                style: const TextStyle(color: Colors.red))),
      );
    }

    final filtered = viewModel.filteredAllTeams;

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
        onRefresh: viewModel.fetchAllTeams,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final t = filtered[index];
            final uid = AuthService.loggedInUserId ?? '';
            final isOwner = uid.isNotEmpty && t.createdBy == uid;
            final isMember = t.isMember || isOwner;
            int maxMm = t.maxMembers > 0 ? t.maxMembers : 4;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _teamCard(t, isOwner, isMember, maxMm),
            );
          },
        ),
      ),
    );
  }

  Widget _teamCard(TeamModel t, bool isOwner, bool isMember, int maxMm) {
    String displayStatus = t.status;
    if (t.status.toLowerCase() == 'approved') {
      displayStatus = t.joinedMembers < maxMm ? 'Open' : 'Full';
    }
    
    final isOpen = displayStatus.toLowerCase() == 'open';
    final isPending = displayStatus.toLowerCase() == 'pending';
    final uid = AuthService.loggedInUserId ?? 'Unknown';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TeamDetailPage(teamId: t.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
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
              style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87),
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
                        child: Builder(
                          builder: (context) {
                            String? avatarUrl;
                            String initial = '';
                            String userId = '';
                            if (t.members.length > i) {
                              final member = t.members[i];
                              initial = member.name.isNotEmpty ? member.name[0].toUpperCase() : '';
                              userId = member.userId;
                              if (member.avatar != null && member.avatar!.isNotEmpty && member.avatar != 'null') {
                                avatarUrl = member.avatar!.startsWith('http') ? member.avatar : TeamApiService.getFullUrl(member.avatar!);
                              }
                            } else if (t.memberNames.length > i) {
                              initial = t.memberNames[i].isNotEmpty ? t.memberNames[i][0].toUpperCase() : '';
                            }
                            
                            Widget fallbackAvatar = CircleAvatar(
                              radius: 14,
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
                                child: initial.isNotEmpty ? Text(
                                  initial,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ) : null,
                              ),
                            );

                            if (avatarUrl != null) {
                              String cacheBustedUrl = avatarUrl!.contains('?') 
                                  ? '$avatarUrl&v=${DateTime.now().millisecondsSinceEpoch}' 
                                  : '$avatarUrl?v=${DateTime.now().millisecondsSinceEpoch}';
                              return CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.transparent,
                                backgroundImage: NetworkImage(cacheBustedUrl),
                              );
                            }

                            if (userId.isNotEmpty) {
                              return FutureBuilder<Map<String, dynamic>?>(
                                future: UserApiService.getUserByIdCached(userId),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data != null) {
                                    final data = snapshot.data!;
                                    String? fetchedPhoto = data['photo']?.toString() ?? data['photo_url']?.toString() ?? data['avatar']?.toString() ?? data['profile_picture']?.toString();
                                    if (fetchedPhoto != null && fetchedPhoto.isNotEmpty) {
                                      fetchedPhoto = fetchedPhoto!.startsWith('http') ? fetchedPhoto : TeamApiService.getFullUrl(fetchedPhoto!);
                                      String cacheBustedUrl = fetchedPhoto!.contains('?') 
                                          ? '$fetchedPhoto&v=${DateTime.now().millisecondsSinceEpoch}' 
                                          : '$fetchedPhoto?v=${DateTime.now().millisecondsSinceEpoch}';
                                      return CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.transparent,
                                        backgroundImage: NetworkImage(cacheBustedUrl),
                                      );
                                    }
                                  }
                                  return fallbackAvatar;
                                },
                              );
                            }

                            return fallbackAvatar;
                          }
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
            if (t.isAcceptedMember) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeamChatPage(teamId: t.id, teamName: t.name),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, 
                      color: Color(0xFF3D5AFE), size: 18),
                  label: const Text(
                    'Buka Chat Tim',
                    style: TextStyle(
                      color: Color(0xFF3D5AFE),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF3D5AFE), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else if (t.isMember) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hourglass_bottom,
                        color: Colors.blue.shade700, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Menunggu Konfirmasi',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
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
