import 'package:flutter/material.dart';
import 'package:younifirst_app/services/api/team_api_service.dart';
import 'package:younifirst_app/models/Teams_model.dart';
import 'package:younifirst_app/views/team/TambahTeams_pages.dart';
import 'package:younifirst_app/views/team/DetailLamaran_pages.dart';
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:younifirst_app/services/input/api_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:younifirst_app/services/api/user_api_service.dart';

class GlobalTeamApplicationsPage extends StatefulWidget {
  final String? initialTeamId;
  const GlobalTeamApplicationsPage({Key? key, this.initialTeamId}) : super(key: key);

  @override
  State<GlobalTeamApplicationsPage> createState() => _GlobalTeamApplicationsPageState();
}

class _GlobalTeamApplicationsPageState extends State<GlobalTeamApplicationsPage> {
  List<TeamModel> _myTeams = [];
  List<Map<String, dynamic>> _allApplications = [];
  Map<String, List<Map<String, dynamic>>> _groupedApplications = {};
  Set<String> _expandedTeamIds = {};
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'Semua';
  bool _isSearching = false;
  String _searchQuery = '';

  final List<Map<String, dynamic>> _filters = [
    {'label': 'Semua', 'icon': Icons.check_circle_rounded},
    {'label': 'Menunggu', 'icon': Icons.access_time_rounded},
    {'label': 'Diterima', 'icon': Icons.check_circle_outline_rounded},
    {'label': 'Ditolak', 'icon': Icons.cancel_outlined},
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
      
      // Filter only teams where the user is the owner
      final ownerTeams = teams.where((t) => t.isOwner).toList();
      
      Map<String, List<Map<String, dynamic>>> grouped = {};
      List<Map<String, dynamic>> allApps = [];

      for (var t in ownerTeams) {
        try {
          final teamApps = await TeamApiService.getTeamApplications(
            t.id,
            status: _selectedFilter.toLowerCase(),
          );

          // attach team info and filter out the owner
          final filteredApps = teamApps.where((a) {
            final applicantId = a['user_id']?.toString() ?? a['member_id']?.toString() ?? '';
            return applicantId != t.createdBy;
          }).toList();

          for (var a in filteredApps) {
            a['team_name'] = t.name;
            a['team_id'] = t.id;
          }
          
          grouped[t.id] = filteredApps;
          allApps.addAll(filteredApps);
          
          if (filteredApps.isNotEmpty) {
            _expandedTeamIds.add(t.id);
          }
        } catch (e) {
          grouped[t.id] = [];
        }
      }

      if (widget.initialTeamId != null) {
        _expandedTeamIds.add(widget.initialTeamId!);
      }

      if (mounted) {
        setState(() {
          _myTeams = ownerTeams;
          _allApplications = allApps;
          _groupedApplications = grouped;
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

  void _toggleExpand(String teamId) {
    setState(() {
      if (_expandedTeamIds.contains(teamId)) {
        _expandedTeamIds.remove(teamId);
      } else {
        _expandedTeamIds.add(teamId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).iconTheme.color,
        elevation: 0,
        centerTitle: false,
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: 'Cari lamaran...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : Text('Lamaran Masuk',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, size: 24, color: Theme.of(context).iconTheme.color),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            height: 60,
            padding: const EdgeInsets.only(bottom: 12),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final f = _filters[index];
                final isSelected = _selectedFilter == f['label'];
                return _buildFilterChip(
                  label: f['label'],
                  icon: f['icon'],
                  isSelected: isSelected,
                  onTap: () => _onFilterChanged(f['label']),
                  isDark: isDark,
                );
              },
            ),
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
                  : (() {
                      final filteredTeams = _myTeams.where((t) => t.name.toLowerCase().contains(_searchQuery)).toList();
                      if (filteredTeams.isEmpty) {
                        return Center(child: Text("Tidak ada lamaran yang cocok dengan '$_searchQuery'"));
                      }
                      return RefreshIndicator(
                        onRefresh: _loadData,
                        color: const Color(0xFF3D5AFE),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                          itemCount: filteredTeams.length,
                          itemBuilder: (_, i) {
                            final team = filteredTeams[i];
                            return _buildTeamSection(team);
                          },
                        ),
                      );
                    })(),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3D5AFE) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF3D5AFE) : (isDark ? Colors.grey.shade700 : const Color(0xFF3D5AFE).withOpacity(0.4)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : const Color(0xFF3D5AFE)),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : const Color(0xFF3D5AFE)),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection(TeamModel team) {
    final apps = _groupedApplications[team.id] ?? [];
    final isExpanded = _expandedTeamIds.contains(team.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // Header Tim
          InkWell(
            onTap: () => _toggleExpand(team.id),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.groups_outlined,
                        color: Color(0xFF3D5AFE), size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          '${apps.length} lamaran',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          
          if (isExpanded) ...[
            if (apps.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text('Belum ada lamaran', style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: apps.length,
                separatorBuilder: (_, __) => Divider(height: 32, color: Colors.grey.shade100),
                itemBuilder: (_, i) => _buildApplicationCard(apps[i]),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app) {
    final name = app['user_name'] ?? app['user']?['name'] ?? 'Pelamar';
    final status = (app['member_status'] ?? app['status'] ?? app['membership_status'] ?? 'pending').toString().toLowerCase();
    final applicationId = app['id']?.toString() ?? app['member_id']?.toString() ?? '';
    final userId = app['user_id']?.toString() ?? 
                   (app['user'] is Map ? app['user']['id']?.toString() : null) ?? 
                   (app['member'] is Map ? app['member']['user_id']?.toString() : null) ?? '';
    final teamId = app['team_id'] ?? '';
    final role = app['proposed_role'] ?? app['role'] ?? app['peran'] ?? app['member_role'] ?? app['position'] ?? 'Pelamar';
    final createdAt = app['created_at']?.toString() ?? '';
    final bio = app['description'] ?? app['keterangan'] ?? app['member_description'] ?? app['user']?['bio'] ?? 'Halo! saya tertarik bergabung dengan tim ini...';
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
    
    String timeAgo = 'Baru saja';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) {
        timeAgo = '${diff.inSeconds} dtk lalu';
      } else if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes} mnt lalu';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours} jam lalu';
      } else {
        timeAgo = '${diff.inDays} hari lalu';
      }
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Builder(
              builder: (context) {
                String? photoUrl = app['user_photo']?.toString() ??
                    app['photo']?.toString() ??
                    app['photo_url']?.toString() ??
                    app['avatar']?.toString() ??
                    app['profile_picture']?.toString() ??
                    app['applicant_photo']?.toString() ??
                    app['user_avatar']?.toString() ??
                    (app['user'] is Map ? (app['user']['photo'] ?? app['user']['photo_url'] ?? app['user']['avatar'] ?? app['user']['profile_picture'])?.toString() : null) ??
                    (app['member'] is Map ? (app['member']['photo'] ?? app['member']['photo_url'] ?? app['member']['avatar'] ?? app['member']['profile_picture'])?.toString() : null) ??
                    (app['applicant'] is Map ? (app['applicant']['photo'] ?? app['applicant']['photo_url'] ?? app['applicant']['avatar'] ?? app['applicant']['profile_picture'])?.toString() : null);

                if (photoUrl == 'null') photoUrl = null;
                
                if (photoUrl != null && photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
                  photoUrl = TeamApiService.getFullUrl(photoUrl);
                }

                Widget fallbackAvatar = CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade400,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );

                if (photoUrl != null && photoUrl.isNotEmpty) {
                  String cacheBustedUrl = photoUrl!.contains('?') 
                      ? '$photoUrl&v=${DateTime.now().millisecondsSinceEpoch}' 
                      : '$photoUrl?v=${DateTime.now().millisecondsSinceEpoch}';
                  return CircleAvatar(
                    radius: 25,
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
                            radius: 25,
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
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      _statusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        role,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF3D5AFE),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          bio,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (status == 'pending' && applicationId.isNotEmpty) ...[
              Expanded(
                child: _actionButton(
                  label: 'Tolak',
                  icon: Icons.close_rounded,
                  color: Colors.red,
                  isFilled: false,
                  onTap: () => _handleRespond(teamId, applicationId, 'reject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionButton(
                  label: 'Terima',
                  icon: Icons.check_rounded,
                  color: Colors.green,
                  isFilled: false,
                  onTap: () => _handleRespond(teamId, applicationId, 'accept'),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              flex: 2,
              child: _actionButton(
                label: 'Lihat Detail Lamaran',
                icon: Icons.assignment_outlined,
                color: const Color(0xFF3D5AFE),
                isFilled: true,
                showArrow: true,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailLamaranPage(
                        app: app,
                        teamId: teamId,
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadData();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isFilled,
    bool showArrow = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isFilled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isFilled ? null : Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isFilled ? Colors.white : color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isFilled ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    IconData icon;
    
    if (['accepted', 'approved', 'active', 'diterima', 'setuju'].contains(status)) {
      color = Colors.green;
      label = 'Diterima';
      icon = Icons.check_circle_outline_rounded;
    } else if (['rejected', 'ditolak', 'tidak setuju'].contains(status)) {
      color = Colors.red;
      label = 'Ditolak';
      icon = Icons.cancel_outlined;
    } else {
      color = Colors.orange;
      label = 'Menunggu';
      icon = Icons.access_time_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRespond(String teamId, String memberId, String action) async {
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
      await TeamApiService.respondToJoin(teamId, memberId, action, rejectionReason: rejectionReason);
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

  Widget _buildEmptyNoTeams() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search_outlined, size: 100, color: const Color(0xFF3D5AFE).withOpacity(0.5)),
            const SizedBox(height: 24),
            const Text(
              'Belum ada tim',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kamu belum membuat tim. Mulai buat tim dan atur lamaran masuk di sini!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TambahTeamsPage()),
                );
                if (result == true) _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D5AFE),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Buat Tim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
