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
      backgroundColor: const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3D5AFE), Color(0xFF1A237E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Tim Saya',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _load,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white))
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
                                    itemBuilder: (_, i) =>
                                        _buildTeamCard(_teams[i]),
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ],
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
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ],
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.groups_outlined,
                        color: Color(0xFF3D5AFE), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              _statusChip(displayStatus),
            ],
          ),
          const SizedBox(height: 8),

          // Lomba
          Text(
            '→ ${t.lombaName}',
            style: const TextStyle(
                color: Color(0xFF3D5AFE),
                fontWeight: FontWeight.w500,
                fontSize: 13),
          ),
          const SizedBox(height: 6),

          // Desc
          Text(
            t.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),

          // Stats
          Text(
            '${t.joinedMembers}/${t.maxMembers} Anggota',
            style: const TextStyle(
                color: Color(0xFF3D5AFE),
                fontWeight: FontWeight.w500,
                fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Action buttons
          if (!isPending)
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
                      'Lamaran Masuk',
                      style: TextStyle(
                          color: Color(0xFF3D5AFE),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3D5AFE)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildChatButton(t),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.orange.shade200),
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

  Widget _buildChatButton(TeamModel t) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TeamChatPage(teamId: t.id, teamName: t.name),
        ),
      ),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF3D5AFE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.chat_bubble_outline,
            color: Colors.white, size: 20),
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
