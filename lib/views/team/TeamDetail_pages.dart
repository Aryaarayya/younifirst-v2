import 'package:flutter/material.dart';
import 'package:younifirst_app/models/Teams_model.dart';
import 'package:younifirst_app/services/api/team_api_service.dart';
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:younifirst_app/views/team/TeamApplications_pages.dart';
import 'package:younifirst_app/views/team/GlobalTeamApplications_pages.dart';
import 'package:younifirst_app/views/team/TeamChat_pages.dart';
import 'package:younifirst_app/views/team/DaftarTim_pages.dart';
import 'package:younifirst_app/views/team/CreateReport_pages.dart';
import 'package:younifirst_app/services/api/user_api_service.dart';
import 'package:younifirst_app/services/api/team_api_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:younifirst_app/views/team/UpdateTeam_pages.dart';

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

  Future<void> _deleteTeam() async {
    final teamName = _team?.name ?? 'Tim';
    bool confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/pop-up/hapus-event.png',
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete_outline, size: 80, color: Colors.red),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Hapus Tim?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
                      height: 1.5,
                      fontFamily: 'Inter',
                    ),
                    children: [
                      const TextSpan(text: 'Tim '),
                      TextSpan(
                        text: teamName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' akan dihapus secara permanen dan tidak dapat dipulihkan kembali. Apakah kamu yakin ingin melanjutkan?'),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3B30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Hapus Tim',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.white,
                    ),
                    child: Text(
                      'Batalkan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ) ?? false;

    if (!confirm) return;

    try {
      await TeamApiService.deleteTeam(widget.teamId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tim berhasil dihapus')),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

  String cacheBustedUrl(String url) {
    if (url.contains('?')) return '$url&v=${DateTime.now().millisecondsSinceEpoch}';
    return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Widget _buildAvatar(TeamMember member) {
    String initial = member.name.isNotEmpty ? member.name.substring(0, 1).toUpperCase() : '?';
    Widget fallback = CircleAvatar(
      radius: 20,
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
            fontSize: 16,
          ),
        ),
      ),
    );

    String? fullAvatarUrl;
    if (member.avatar != null && member.avatar!.isNotEmpty && member.avatar != 'null') {
      fullAvatarUrl = member.avatar!.startsWith('http') ? member.avatar : TeamApiService.getFullUrl(member.avatar!);
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.transparent,
        backgroundImage: NetworkImage(cacheBustedUrl(fullAvatarUrl!)),
      );
    }

    if (member.userId.isNotEmpty) {
      return FutureBuilder<Map<String, dynamic>?>(
        future: UserApiService.getUserByIdCached(member.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.transparent,
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
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
              radius: 20,
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

  Widget _buildBody() {
    final t = _team!;
    
    final isOwner = t.isOwner ||
        (AuthService.loggedInUserId != null &&
            t.createdBy == AuthService.loggedInUserId);
            


    int maxMm = t.maxMembers > 0 ? t.maxMembers : 4;
    String displayStatus = t.status;
    if (t.status.toLowerCase() == 'approved') {
      displayStatus = t.joinedMembers < maxMm ? 'Open' : 'Full';
    }

    final isOpen = displayStatus.toLowerCase() == 'open';
    final isPending = displayStatus.toLowerCase() == 'pending';

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
                    if (isOwner)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          offset: const Offset(0, 50),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => UpdateTeamPage(team: t)),
                              );
                              if (result == true) {
                                _load();
                              }
                            } else if (value == 'hapus') {
                              _deleteTeam();
                            } else if (value == 'bagikan') {
                              final textToShare = "Yuk gabung tim ${t.name}! Cek di Younifirst sekarang.";
                              Share.share(textToShare);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem(
                              value: 'edit',
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 22, color: Theme.of(context).textTheme.bodyLarge?.color),
                                  const SizedBox(width: 16),
                                  Text('Edit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'hapus',
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 22, color: Theme.of(context).textTheme.bodyLarge?.color),
                                  const SizedBox(width: 16),
                                  Text('Hapus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'bagikan',
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.share_outlined, size: 22, color: Theme.of(context).textTheme.bodyLarge?.color),
                                  const SizedBox(width: 16),
                                  Text('Bagikan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox(width: 40),
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
                          color: Theme.of(context).cardColor,
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
                            Text(
                              'Persyaratan',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t.description,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  height: 1.5),
                            ),
                            const SizedBox(height: 20),

                            // Anggota
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Anggota Tim',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Theme.of(context).textTheme.bodyLarge?.color),
                                ),
                                Text(
                                  '(${t.joinedMembers})',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (t.members.isNotEmpty)
                              ...t.members.map((member) {
                                final isMe = member.userId == AuthService.loggedInUserId ||
                                    (AuthService.loggedInUserName != null && 
                                     member.name.toLowerCase().trim() == AuthService.loggedInUserName!.toLowerCase().trim());
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      _buildAvatar(member),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  member.name,
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context).textTheme.bodyLarge?.color),
                                                ),
                                                if (isMe) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF3D5AFE),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: const Text(
                                                      'Anda',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              member.role,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54),
                                            ),
                                            if (member.timeAgo.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                member.timeAgo,
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList()
                            else
                              Text(
                                t.joinedMembers > 0
                                    ? '${t.joinedMembers} anggota'
                                    : 'Belum ada anggota',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),

                            if (isOwner && t.status.toLowerCase() != 'rejected') ...[
                              const SizedBox(height: 16),
                              const Divider(color: Color(0xFFE5E7EB)),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '🏆 Laporan Juara',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Theme.of(context).textTheme.bodyLarge?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Belum ada laporan prestasi tim',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CreateReportPage(team: t),
                                            ),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Color(0xFF3D5AFE)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: const Text(
                                          '+ Kirim Laporan Juara',
                                          style: TextStyle(
                                            color: Color(0xFF3D5AFE),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Status pending info
                      if (isPending)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.orange.withValues(alpha: 0.1) : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.orange.withValues(alpha: 0.3) : Colors.orange.shade200, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.hourglass_top,
                                  color: Colors.orange.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tim sedang dalam proses review admin. Notifikasi akan dikirim setelah disetujui.',
                                  style: TextStyle(
                                      fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Status rejected info
                      if (t.status.toLowerCase() == 'rejected' && t.rejectionReason != null && t.rejectionReason!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.red.withValues(alpha: 0.3) : Colors.red.shade200, width: 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, color: Colors.red.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Alasan Penolakan',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      t.rejectionReason!,
                                      style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87),
                                    ),
                                  ],
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
        if (t.status.toLowerCase() != 'rejected')
          Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30), // match mockup safe area
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
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
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GlobalTeamApplicationsPage(initialTeamId: t.id),
                        ),
                      ),
                      icon: const Icon(Icons.assignment_turned_in_outlined, color: Colors.white, size: 20),
                      label: const Text(
                        'Lihat Lamaran Masuk',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D5AFE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeamChatPage(teamId: t.id, teamName: t.name),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: const Color(0xFF3D5AFE),
                      padding: const EdgeInsets.all(16),
                      elevation: 0,
                    ),
                    child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                  ),
                ] else if (t.isAcceptedMember) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeamChatPage(teamId: t.id, teamName: t.name),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                      label: const Text(
                        'BUKA CHAT TIM',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D5AFE),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                    ),
                  ),
                ] else if (t.isRejectedMember) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Lamaran Ditolak', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                            content: Text(
                              t.memberRejectionReason ?? 'Tidak ada alasan spesifik yang diberikan oleh ketua tim.',
                              style: const TextStyle(fontSize: 14, height: 1.5),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Tutup', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      label: const Text(
                        'LAMARAN DITOLAK',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                    ),
                  ),
                ] else if (t.isMember) ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade600 : Colors.grey.shade300),
                      ),
                      child: const Center(
                        child: Text(
                          'MENUNGGU KONFIRMASI',
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;
    if (s == 'open') {
      bg = isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.shade100;
      fg = isDark ? Colors.green.shade300 : Colors.green.shade700;
    } else if (s == 'pending') {
      bg = isDark ? Colors.orange.withValues(alpha: 0.15) : Colors.orange.shade100;
      fg = isDark ? Colors.orange.shade300 : Colors.orange.shade800;
    } else if (s == 'full') {
      bg = isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade100;
      fg = isDark ? Colors.red.shade300 : Colors.red.shade700;
    } else {
      bg = isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade100;
      fg = isDark ? Colors.red.shade300 : Colors.red.shade700;
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
