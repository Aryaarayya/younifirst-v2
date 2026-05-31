import 'package:flutter/material.dart';
import 'package:younifirst_app/services/api/team_api_service.dart';
import 'package:younifirst_app/views/team/TambahTeams_pages.dart';
import 'package:younifirst_app/views/team/DetailLamaran_pages.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:younifirst_app/services/input/api_client.dart';
import 'package:younifirst_app/services/api/user_api_service.dart';
import 'dart:convert';
import 'dart:io';

class TeamApplicationsPage extends StatefulWidget {
  final String teamId;
  final String teamName;

  const TeamApplicationsPage({
    Key? key,
    required this.teamId,
    required this.teamName,
  }) : super(key: key);

  @override
  State<TeamApplicationsPage> createState() => _TeamApplicationsPageState();
}

class _TeamApplicationsPageState extends State<TeamApplicationsPage> {
  List<Map<String, dynamic>> _applications = [];
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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apps = await TeamApiService.getTeamApplications(
        widget.teamId,
        status: _selectedFilter.toLowerCase(),
      );
      if (mounted) setState(() => _applications = apps);
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
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
              Divider(height: 1, color: Theme.of(context).dividerColor),
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
              Divider(height: 1, color: Theme.of(context).dividerColor),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3D5AFE)))
          : _error != null
              ? _buildError()
              : _applications.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFF3D5AFE),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _applications.length,
                        itemBuilder: (_, i) =>
                            _buildApplicationCard(_applications[i]),
                      ),
                    ),
    );
  }

  String cacheBustedUrl(String url) {
    if (url.contains('?')) return '$url&v=${DateTime.now().millisecondsSinceEpoch}';
    return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Widget _buildAvatar(Map<String, dynamic> app, String name, String userId) {
    String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    Widget fallback = CircleAvatar(
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

    String? avatar = app['photo']?.toString() ??
        app['photo_url']?.toString() ??
        app['avatar']?.toString() ??
        app['profile_picture']?.toString() ??
        app['user']?['photo']?.toString() ??
        app['user']?['photo_url']?.toString() ??
        app['user']?['avatar']?.toString() ??
        app['user_avatar']?.toString();
    
    if (avatar != null && avatar.isNotEmpty && avatar != 'null') {
      final fullUrl = avatar.startsWith('http') ? avatar : TeamApiService.getFullUrl(avatar);
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.transparent,
        backgroundImage: NetworkImage(cacheBustedUrl(fullUrl)),
      );
    }

    if (userId.isNotEmpty) {
      return FutureBuilder<Map<String, dynamic>?>(
        future: UserApiService.getUserByIdCached(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.transparent,
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          String? fetchedPhoto;
          if (snapshot.hasData && snapshot.data != null) {
            final data = snapshot.data!;
            fetchedPhoto = data['photo']?.toString() ?? data['photo_url']?.toString() ?? data['avatar']?.toString() ?? data['profile_picture']?.toString();
            if (fetchedPhoto != null && fetchedPhoto.isNotEmpty) {
              fetchedPhoto = fetchedPhoto.startsWith('http') ? fetchedPhoto : TeamApiService.getFullUrl(fetchedPhoto);
            }
          }
          if (fetchedPhoto != null && fetchedPhoto.isNotEmpty) {
            return CircleAvatar(
              radius: 24,
              backgroundColor: Colors.transparent,
              backgroundImage: NetworkImage(cacheBustedUrl(fetchedPhoto!)),
            );
          }
          return fallback;
        },
      );
    }

    return fallback;
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
          color: isSelected ? const Color(0xFF3D5AFE) : Theme.of(context).cardColor,
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
    final status = (app['member_status'] ?? app['status'] ?? app['membership_status'] ?? 'pending').toString().toLowerCase();
    final memberId = app['member_id']?.toString() ?? app['user_id']?.toString() ?? app['id']?.toString() ?? '';
    final role = app['proposed_role'] ?? app['role'] ?? app['peran'] ?? app['member_role'] ?? app['position'] ?? 'Pelamar';
    final bio = app['description'] ?? app['keterangan'] ?? app['member_description'] ?? app['user']?['bio'] ?? 'Halo! saya tertarik bergabung...';
    final email = app['user_email']?.toString() ?? '';
    final nim = app['nim']?.toString() ?? '';
    String cvUrl = app['cv']?.toString() ?? app['cv_url']?.toString() ?? app['cv_path']?.toString() ?? app['portfolio_url']?.toString() ?? app['portfolio']?.toString() ?? '';
    if (cvUrl.isEmpty && app['user'] is Map) {
      cvUrl = app['user']['cv']?.toString() ?? app['user']['cv_url']?.toString() ?? app['user']['cv_path']?.toString() ?? app['user']['portfolio_url']?.toString() ?? app['user']['portfolio']?.toString() ?? '';
    }
    if (cvUrl.isEmpty && app['member'] is Map) {
      cvUrl = app['member']['cv']?.toString() ?? app['member']['cv_url']?.toString() ?? app['member']['cv_path']?.toString() ?? app['member']['portfolio_url']?.toString() ?? app['member']['portfolio']?.toString() ?? '';
    }
    if (cvUrl == 'null') cvUrl = '';

    if (cvUrl.isNotEmpty && !cvUrl.startsWith('http')) {
      final baseDomain = ApiClient.baseUrl.replaceAll('/api', '');
      cvUrl = cvUrl.startsWith('/') ? '$baseDomain$cvUrl' : '$baseDomain/storage/$cvUrl';
    }
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAvatar(app, name, memberId),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    if (nim.isNotEmpty)
                      Text(nim,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
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
          const SizedBox(height: 12),
          Text(
            role,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF3D5AFE), fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            bio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600),
          ),

          const SizedBox(height: 14),
          Row(
            children: [
              if (status == 'pending' && memberId.isNotEmpty) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleRespond(memberId, 'reject'),
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
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleRespond(memberId, 'accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailLamaranPage(
                          app: app,
                          teamId: widget.teamId,
                        ),
                      ),
                    );
                    if (result == true) {
                      _load();
                    }
                  },
                  icon: const Icon(Icons.assignment_outlined, size: 16),
                  label: const Text('Lihat Detail Lamaran',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5AFE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleRespond(String memberId, String action) async {
    String? rejectionReason;
    if (action == 'reject') {
      rejectionReason = await showDialog<String>(
        context: context,
        builder: (context) {
          final TextEditingController reasonController = TextEditingController();
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Tolak Lamaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Berikan alasan penolakan (Wajib):', style: TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Kuota tim sudah penuh',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (reasonController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Alasan penolakan wajib diisi'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  Navigator.pop(context, reasonController.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Tolak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );

      if (rejectionReason == null) return; // Batal ditekan
    }

    try {
      await TeamApiService.respondToJoin(widget.teamId, memberId, action, rejectionReason: rejectionReason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'accept'
              ? 'Anggota berhasil diterima!'
              : 'Lamaran ditolak.'),
          backgroundColor: action == 'accept' ? Colors.green : Colors.orange,
        ),
      );
      _load(); // refresh list
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
    if (['accepted', 'approved', 'active', 'diterima', 'setuju'].contains(status)) {
      bg = Theme.of(context).brightness == Brightness.dark ? Colors.green.shade900 : Colors.green.shade100;
      fg = Theme.of(context).brightness == Brightness.dark ? Colors.green.shade300 : Colors.green.shade700;
      label = 'Diterima';
    } else if (status == 'rejected') {
      bg = Theme.of(context).brightness == Brightness.dark ? Colors.red.shade900 : Colors.red.shade100;
      fg = Theme.of(context).brightness == Brightness.dark ? Colors.red.shade300 : Colors.red.shade700;
      label = 'Ditolak';
    } else {
      bg = Theme.of(context).brightness == Brightness.dark ? Colors.orange.shade900 : Colors.orange.shade100;
      fg = Theme.of(context).brightness == Brightness.dark ? Colors.orange.shade300 : Colors.orange.shade800;
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

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_outlined, size: 100, color: const Color(0xFF3D5AFE).withOpacity(0.8)),
            const SizedBox(height: 12),
            Text(
              'Belum ada lamaran',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 12),
            Text(
              'Saat ini belum ada lamaran masuk untuk kategori ini. Silakan cek kembali nanti!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white60 : Colors.black54, fontSize: 14, height: 1.5),
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
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

