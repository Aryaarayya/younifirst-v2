import 'package:flutter/material.dart';
import 'package:younifirst_app/services/api/team_api_service.dart';
import 'package:younifirst_app/services/input/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailLamaranPage extends StatefulWidget {
  final Map<String, dynamic> app;
  final String teamId;

  const DetailLamaranPage({
    Key? key,
    required this.app,
    required this.teamId,
  }) : super(key: key);

  @override
  State<DetailLamaranPage> createState() => _DetailLamaranPageState();
}

class _DetailLamaranPageState extends State<DetailLamaranPage> {
  bool _isResponding = false;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final name = app['user_name'] ??
        app['user']?['name'] ??
        app['applicant_name'] ??
        'Pelamar';
    final status = (app['member_status'] ?? app['status'] ?? app['membership_status'] ?? 'pending').toString().toLowerCase();
    final memberId = app['member_id']?.toString() ?? app['user_id']?.toString() ?? app['id']?.toString() ?? '';
    final role = app['proposed_role'] ?? app['role'] ?? app['peran'] ?? app['member_role'] ?? app['position'] ?? 'Pelamar';
    final bio = app['description'] ?? app['keterangan'] ?? app['member_description'] ?? app['user']?['bio'] ?? 'Halo! saya tertarik bergabung...';

    // Parse CV URL
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

    // Parse Photo URL
    String? photoUrl;
    if (app['user_photo'] != null && app['user_photo'].toString().isNotEmpty) {
      photoUrl = app['user_photo'].toString();
    } else if (app['user'] is Map) {
      final u = app['user'];
      photoUrl = u['photo_url']?.toString() ?? u['photo']?.toString();
    }

    if (photoUrl != null && photoUrl.isNotEmpty && !photoUrl.startsWith('http')) {
      final baseDomain = ApiClient.baseUrl.replaceAll('/api', '');
      photoUrl = photoUrl.startsWith('/') ? '$baseDomain$photoUrl' : '$baseDomain/storage/$photoUrl';
    }

    // Parse relative time
    final createdAt = app['created_at']?.toString() ?? '';
    String timeAgo = 'Baru saja';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) {
        timeAgo = '${diff.inSeconds} dtk yang lalu';
      } else if (diff.inMinutes < 60) {
        timeAgo = '${diff.inMinutes} mnt yang lalu';
      } else if (diff.inHours < 24) {
        timeAgo = '${diff.inHours} jam yang lalu';
      } else {
        timeAgo = '${diff.inDays} hari yang lalu';
      }
    } catch (_) {}

    // Clean CV File Name
    String cvFileName = 'CV Pelamar';
    String fileExt = 'pdf';
    if (cvUrl.isNotEmpty) {
      final cleanName = name.replaceAll(' ', '_');
      try {
        final uri = Uri.parse(cvUrl);
        final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
        if (segment.contains('.')) {
          fileExt = segment.split('.').last.toLowerCase();
        }
      } catch (_) {}
      cvFileName = '${cleanName}_CV.$fileExt';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Lamaran',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFE8EAFF),
                          backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                              ? NetworkImage(photoUrl)
                              : null,
                          child: (photoUrl == null || photoUrl.isEmpty)
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    color: Color(0xFF3D5AFE),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeAgo,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_horiz, color: Colors.grey),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: Color(0xFFF1F1F1)),
                    const SizedBox(height: 20),

                    // CV Section
                    const Text(
                      'CV Pelamar',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          // PDF / File Icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.picture_as_pdf,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // File Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cvFileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${fileExt.toUpperCase()} • Dokumen',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Download Button
                          ElevatedButton.icon(
                            onPressed: () async {
                              if (cvUrl.isNotEmpty) {
                                final uri = Uri.parse(cvUrl);
                                try {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                } catch (_) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Tidak dapat mengunduh CV')),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tautan CV tidak tersedia')),
                                );
                              }
                            },
                            icon: const Icon(Icons.download_rounded, size: 14, color: Colors.white),
                            label: const Text(
                              'Unduh',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3D5AFE),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: Color(0xFFF1F1F1)),
                    const SizedBox(height: 20),

                    // Proposed Role
                    const Text(
                      'Peran yang Diajukan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      role,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: Color(0xFFF1F1F1)),
                    const SizedBox(height: 20),

                    // Keterangan / Cover Letter
                    const Text(
                      'Keterangan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bio,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Bar (if status is pending)
            if (status == 'pending')
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: _isResponding
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF3D5AFE)),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _handleAction(memberId, 'reject'),
                              icon: const Icon(Icons.close, color: Colors.red, size: 18),
                              label: const Text(
                                'Tolak',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red, width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleAction(memberId, 'accept'),
                              icon: const Icon(Icons.check, color: Colors.white, size: 18),
                              label: const Text(
                                'Terima',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3D5AFE),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
              )
            else
              // Show Status Badge at the bottom if already decided
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: _getStatusColor(status).withOpacity(0.1),
                alignment: Alignment.center,
                child: Text(
                  'Status Lamaran: ${_getStatusLabel(status)}',
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (['accepted', 'approved', 'active', 'diterima', 'setuju'].contains(status)) {
      return Colors.green;
    } else if (status == 'rejected') {
      return Colors.red;
    }
    return Colors.orange;
  }

  String _getStatusLabel(String status) {
    if (['accepted', 'approved', 'active', 'diterima', 'setuju'].contains(status)) {
      return 'Diterima';
    } else if (status == 'rejected') {
      return 'Ditolak';
    }
    return 'Menunggu';
  }

  Future<void> _handleAction(String memberId, String action) async {
    setState(() => _isResponding = true);
    try {
      await TeamApiService.respondToJoin(widget.teamId, memberId, action);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'accept'
              ? 'Anggota berhasil diterima!'
              : 'Lamaran ditolak.'),
          backgroundColor: action == 'accept' ? Colors.green : Colors.orange,
        ),
      );
      Navigator.pop(context, true); // Return true to indicate status changed
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResponding = false);
    }
  }
}
