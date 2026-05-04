import 'package:flutter/material.dart';
import 'package:younifirst_app/models/Teams_model.dart';
import 'package:younifirst_app/services/team_api_service.dart';
import 'package:younifirst_app/services/auth_service.dart';
import 'package:younifirst_app/pages/team/TeamApplications_pages.dart';
import 'package:younifirst_app/pages/team/TeamChat_pages.dart';
import 'package:younifirst_app/pages/team/DaftarTim_pages.dart';

class TeamDetailPage extends StatefulWidget {
  final String teamId;
  const TeamDetailPage({Key? key, required this.teamId}) : super(key: key);

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> {
  TeamModel? _team;
  bool _isLoading = true;
  String? _error;

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
      final t = await TeamApiService.getTeamDetail(widget.teamId);
      if (mounted) setState(() => _team = t);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3D5AFE)))
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() => Center(
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

  Widget _buildBody() {
    final t = _team!;
    
    int maxMm = t.maxMembers > 0 ? t.maxMembers : 4;
    String displayStatus = t.status;
    if (t.status.toLowerCase() == 'approved') {
      displayStatus = t.joinedMembers < maxMm ? 'Open' : 'Full';
    }

    final isOpen = displayStatus.toLowerCase() == 'open';
    final isPending = displayStatus.toLowerCase() == 'pending';
    final isOwner = t.isOwner ||
        (AuthService.loggedInUserId != null &&
            t.createdBy == AuthService.loggedInUserId);

    return Stack(
      children: [
        // Top Graphic header
        Container(
          height: 250,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF3D5AFE),
            // Fallback gradient if you prefer:
            // gradient: LinearGradient(
            //   colors: [Color(0xFF3D5AFE), Color(0xFF1A237E)],
            //   begin: Alignment.topLeft,
            //   end: Alignment.bottomRight,
            // ),
          ),
          child: Opacity(
            opacity: 0.1,
            child: Image.asset(
              'assets/images/logo_putih.png', // Using existing asset as pattern placeholder
              repeat: ImageRepeat.repeat,
              fit: BoxFit.none,
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Detail Tim',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  child: Column(
                    children: [
                      // Main card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status badge + nama tim
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    t.name,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                _statusBadge(displayStatus),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${t.joinedMembers} anggota saat ini  •  ${t.maxMembers} Max',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 12),

                            // Nama lomba
                            InkWell(
                              child: Text(
                                '→ ${t.lombaName}',
                                style: const TextStyle(
                                    color: Color(0xFF3D5AFE),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Deskripsi / Persyaratan
                            const Text(
                              'Persyaratan',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t.description,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.5),
                            ),
                            const SizedBox(height: 20),

                            // Anggota
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Anggota Tim',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                Text(
                                  '(${t.joinedMembers})',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (t.memberNames.isNotEmpty)
                              ...t.memberNames.map((name) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor:
                                              const Color(0xFFE8EAFF),
                                          child: Text(
                                            name.substring(0, 1).toUpperCase(),
                                            style: const TextStyle(
                                                color: Color(0xFF3D5AFE),
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(name,
                                                  style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold, color: Colors.black87)),
                                              const SizedBox(height: 2),
                                              const Text("Member", // Default role
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black54)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))
                            else
                              Text(
                                t.joinedMembers > 0
                                    ? '${t.joinedMembers} anggota'
                                    : 'Belum ada anggota',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                          ],
                        ),
                      ),

                      // Status pending info
                      if (isPending)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.shade200, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.hourglass_top,
                                  color: Colors.orange.shade700),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Tim sedang dalam proses review admin. Notifikasi akan dikirim setelah disetujui.',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Bottom action buttons
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30), // match mockup safe area
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Row(
              children: [
                if (isOwner) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TeamApplicationsPage(teamId: t.id, teamName: t.name),
                        ),
                      ),
                      icon: const Icon(Icons.description_outlined,
                          color: Color(0xFF3D5AFE), size: 18),
                      label: const Text(
                        'Lihat Lamaran',
                        style: TextStyle(
                            color: Color(0xFF3D5AFE),
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3D5AFE)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ] else if (!isOwner) ...[
                  Expanded(child: _buildApplyButton(t)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatButton(TeamModel t) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF3D5AFE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeamChatPage(teamId: t.id, teamName: t.name),
          ),
        ),
      ),
    );
  }

  Widget _buildApplyButton(TeamModel t) {
    return ElevatedButton(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DaftarTimPage(teamId: t.id, teamName: t.name),
          ),
        );
        if (result == true) {
          _load();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3D5AFE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
      ),
      child: const Text('DAFTAR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _statusBadge(String status) {
    final s = status.toLowerCase();
    Color bg;
    Color fg;
    if (s == 'open') {
      bg = Colors.green.shade100;
      fg = Colors.green.shade700;
    } else if (s == 'pending') {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status,
        style: TextStyle(
            color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
