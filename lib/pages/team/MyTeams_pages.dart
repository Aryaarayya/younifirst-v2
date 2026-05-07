import 'package:flutter/material.dart';
import 'package:younifirst_app/models/Teams_model.dart';
import 'package:younifirst_app/services/team_api_service.dart';
import 'package:younifirst_app/services/auth_service.dart';
import 'package:younifirst_app/pages/team/TeamDetail_pages.dart';
import 'package:younifirst_app/pages/team/TeamApplications_pages.dart';
import 'package:younifirst_app/pages/team/TeamChat_pages.dart';

class MyTeamsPage extends StatefulWidget {
  const MyTeamsPage({Key? key}) : super(key: key);

  @override
  State<MyTeamsPage> createState() => _MyTeamsPageState();
}

class _MyTeamsPageState extends State<MyTeamsPage> {
  List<TeamModel> _teams = [];
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
      final teams = await TeamApiService.getMyTeams();
      if (mounted) setState(() => _teams = teams);
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tim Saya',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF3D5AFE)))
            : _error != null
                ? _buildError()
                : _teams.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: const Color(0xFF3D5AFE),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _teams.length,
                          itemBuilder: (_, i) => _buildTeamCard(_teams[i]),
                        ),
                      ),
      ),
    );
  }

  Widget _buildTeamCard(TeamModel t) {
    int maxMm = t.maxMembers > 0 ? t.maxMembers : 4;
    String displayStatus = t.status;
    if (t.status.toLowerCase() == 'approved') {
      displayStatus = t.joinedMembers < maxMm ? 'Open' : 'Full';
    }
    
    final isPending = displayStatus.toLowerCase() == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
              _statusChip(displayStatus),
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

          // Stats (Avatars + Count)
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
                '${t.joinedMembers}/${maxMm} Anggota',
                style: const TextStyle(
                    color: Color(0xFF3D5AFE),
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          if (!isPending)
            if (t.isOwner)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeamApplicationsPage(
                            teamId: t.id,
                            teamName: t.name,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.description_outlined,
                          size: 16, color: Color(0xFF3D5AFE)),
                      label: const Text(
                        'Lihat Lamaran Masuk',
                        style: TextStyle(
                            color: Color(0xFF3D5AFE),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3D5AFE)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeamChatPage(teamId: t.id, teamName: t.name),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3D5AFE)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Chat Tim',
                          style: TextStyle(
                              color: Color(0xFF3D5AFE),
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.chat_bubble_rounded, size: 16, color: Color(0xFF3D5AFE)),
                      ],
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeamChatPage(teamId: t.id, teamName: t.name),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF3D5AFE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Buka Chat Tim',
                        style: TextStyle(
                          color: Color(0xFF3D5AFE),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.chat_bubble_rounded, color: Color(0xFF3D5AFE), size: 20),
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                '2',
                                style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_top,
                      color: Colors.orange.shade700, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Menunggu persetujuan admin...',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status,
        style: TextStyle(
            color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.group_off_outlined,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Belum ada tim',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black54)),
          const SizedBox(height: 8),
          const Text('Tim yang kamu buat akan muncul di sini',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
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
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D5AFE)),
          ),
        ],
      ),
    );
  }
}
