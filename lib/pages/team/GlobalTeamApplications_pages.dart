import 'package:flutter/material.dart';
import 'package:younifirst_app/services/team_api_service.dart';
import 'package:younifirst_app/models/Teams_model.dart';
import 'package:younifirst_app/pages/team/TambahTeams_pages.dart';

class GlobalTeamApplicationsPage extends StatefulWidget {
  const GlobalTeamApplicationsPage({Key? key}) : super(key: key);

  @override
  State<GlobalTeamApplicationsPage> createState() => _GlobalTeamApplicationsPageState();
}

class _GlobalTeamApplicationsPageState extends State<GlobalTeamApplicationsPage> {
  List<TeamModel> _myTeams = [];
  List<Map<String, dynamic>> _allApplications = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'Semua';

  final List<Map<String, dynamic>> _filters = [
    {'label': 'Semua', 'icon': Icons.check_circle, 'color': Colors.blue},
    {'label': 'Menunggu', 'icon': Icons.access_time, 'color': Colors.blue},
    {'label': 'Diterima', 'icon': Icons.check_circle_outline, 'color': Colors.blue},
    {'label': 'Ditolak', 'icon': Icons.cancel_outlined, 'color': Colors.blue},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final teams = await TeamApiService.getMyTeams();
      
      // If the user has teams, fetch applications for all of them
      List<Map<String, dynamic>> apps = [];
      for (var t in teams) {
        if (t.isOwner || t.isMember) { // Only fetch if they have some management role, though any of myTeams works
          try {
            final teamApps = await TeamApiService.getTeamApplications(
              t.id,
              status: _selectedFilter.toLowerCase(),
            );
            // attach team info
            for (var a in teamApps) {
              a['team_name'] = t.name;
              a['team_id'] = t.id;
              print('DEBUG GLOBAL APP PARSED: $a');
            }
            apps.addAll(teamApps);
          } catch (e) {
            // ignore error for a single team and continue
          }
        }
      }

      if (mounted) {
        setState(() {
          _myTeams = teams;
          _allApplications = apps;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        title: const Text('Lamaran Masuk',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 24),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              Divider(height: 1, color: Colors.grey.shade200),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final f = _filters[index];
                    final isSelected = _selectedFilter == f['label'];
                    return _buildFilterChip(
                      label: f['label'],
                      icon: f['icon'],
                      isSelected: isSelected,
                      onTap: () => _onFilterChanged(f['label']),
                    );
                  },
                ),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3D5AFE)))
          : _error != null
              ? _buildError()
              : _myTeams.isEmpty
                  ? _buildEmptyNoTeams()
                  : _allApplications.isEmpty
                      ? _buildEmptyNoApps()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: const Color(0xFF3D5AFE),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _allApplications.length,
                            itemBuilder: (_, i) =>
                                _buildApplicationCard(_allApplications[i]),
                          ),
                        ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3D5AFE) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3D5AFE) : const Color(0xFF3D5AFE).withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app) {
    final name = app['user_name'] ??
        app['user']?['name'] ??
        app['applicant_name'] ??
        'Pelamar';
    final status = (app['member_status'] ?? app['status'] ?? 'pending').toString().toLowerCase();
    final memberId = app['member_id']?.toString() ?? app['user_id']?.toString() ?? app['id']?.toString() ?? '';
    final email = app['user_email']?.toString() ?? '';
    final nim = app['nim']?.toString() ?? '';
    final teamName = app['team_name'] ?? 'Tim';
    final teamId = app['team_id'] ?? '';
    final createdAt = app['created_at']?.toString() ?? '';
    String timeAgo = '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes} mnt lalu';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours} jam lalu';
      } else {
        timeAgo = '${diff.inDays} hari lalu';
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE8EAFF),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Color(0xFF3D5AFE),
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Mendaftar ke $teamName',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF3D5AFE), fontWeight: FontWeight.w500)),
                    if (timeAgo.isNotEmpty)
                      Text(timeAgo,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              _statusChip(status),
            ],
          ),

          // Accept / Reject buttons for pending
          if (status == 'pending' && memberId.isNotEmpty && teamId.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleRespond(teamId, memberId, 'reject'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Tolak',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleRespond(teamId, memberId, 'accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D5AFE),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    child: const Text('Terima',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleRespond(String teamId, String memberId, String action) async {
    try {
      await TeamApiService.respondToJoin(teamId, memberId, action);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'accept'
              ? 'Anggota berhasil diterima!'
              : 'Lamaran ditolak.'),
          backgroundColor: action == 'accept' ? Colors.green : Colors.orange,
        ),
      );
      _loadData(); // refresh list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    String label;
    if (status == 'accepted' || status == 'approved') {
      bg = Colors.green.shade100;
      fg = Colors.green.shade700;
      label = 'Diterima';
    } else if (status == 'rejected') {
      bg = Colors.red.shade100;
      fg = Colors.red.shade700;
      label = 'Ditolak';
    } else {
      bg = Colors.orange.shade100;
      fg = Colors.orange.shade800;
      label = 'Menunggu';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  // Exact UI from the mockup "Belum ada tim"
  Widget _buildEmptyNoTeams() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Using a placeholder icon as illustration, since actual illustration asset is unknown
            Icon(Icons.person_search_outlined, size: 120, color: const Color(0xFF3D5AFE).withOpacity(0.8)),
            const SizedBox(height: 24),
            const Text(
              'Belum ada tim',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              'Kamu belum membuat tim. Mulai buat\ntim dan atur lamaran masuk tim disini!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TambahTeamsPage()),
                );
                if (result == true) _loadData();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Buat Tim'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D5AFE),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI when there are teams but NO applications
  Widget _buildEmptyNoApps() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Belum ada lamaran',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87),
            ),
            const SizedBox(height: 12),
            const Text(
              'Belum ada pendaftar di tim yang kamu buat.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
