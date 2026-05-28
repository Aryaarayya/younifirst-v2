import 'package:younifirst_app/services/input/auth_service.dart';

class TeamMember {
  final String userId;
  final String name;
  final String role;
  final String status;
  final String timeAgo;

  TeamMember({
    required this.userId,
    required this.name,
    required this.role,
    required this.status,
    this.timeAgo = '',
  });
}

class TeamModel {
  final String id;
  final String name;
  final String lombaName;
  final int maxMembers;
  final String description;
  final String status;
  final int joinedMembers;
  final String createdBy;
  final bool isOwner;
  final bool isMember;
  final bool isAcceptedMember;
  final bool isLiked;
  final List<String> memberNames;
  final List<TeamMember> members;

  TeamModel({
    required this.id,
    required this.name,
    required this.lombaName,
    required this.maxMembers,
    required this.description,
    required this.status,
    required this.joinedMembers,
    required this.createdBy,
    this.isOwner = false,
    this.isMember = false,
    this.isAcceptedMember = false,
    this.isLiked = false,
    this.memberNames = const [],
    this.members = const [],
  });

  factory TeamModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    // Backend view_teams returns leader_id, while teams table has created_by
    final createdBy = json['created_by']?.toString() ?? json['leader_id']?.toString() ?? '';
    final members = json['members'];
    List<String> names = [];
    List<TeamMember> parsedMembers = [];
    final cleanUid = currentUserId?.trim();
    final numericUid = cleanUid?.replaceAll(RegExp(r'[^0-9]'), '');
    
    bool isAcceptedRaw = json['is_accepted'] == true || 
                         json['is_accepted'] == 1 || 
                         json['is_accepted'] == 'true' ||
                         json['is_accepted'] == '1' ||
                         json['is_approved'] == true ||
                         json['is_approved'] == 1 ||
                         json['is_approved'] == 'true' ||
                         ['approved', 'accepted', 'active', 'diterima', 'setuju'].contains(json['membership_status']?.toString().toLowerCase());

    bool memberFound = isAcceptedRaw ||
                      json['is_member'] == true || 
                      json['is_member'] == 1 || 
                      json['is_member'] == 'true' ||
                      json['is_member'] == '1' ||
                      json['is_joined'] == true ||
                      json['is_joined'] == 1 ||
                      json['is_joined'] == 'true' ||
                      json['is_joined'] == '1';

    bool isAcceptedByList = false;

    if (members is List || members is Map) {
      final List<dynamic> memberList = members is Map ? members.values.toList() : (members as List);
      
      names = memberList
          .map((m) => (m is Map ? (m['name'] ?? m['user_name'] ?? m['user']?['name'] ?? '') : m).toString())
          .where((n) => n.isNotEmpty)
          .toList();
      
      for (var m in memberList) {
        if (m is Map) {
          final mUserId = m['user_id']?.toString()?.trim() ?? 
                          m['user']?['id']?.toString()?.trim() ?? 
                          m['id']?.toString()?.trim() ?? '';
          final mName = (m['name'] ?? m['user_name'] ?? m['user']?['name'] ?? '').toString();
          final mRole = (m['proposed_role'] ?? m['role'] ?? m['peran'] ?? m['member_role'] ?? m['position'] ?? 'Member').toString();
          final mStatus = (m['member_status'] ?? m['status'] ?? m['membership_status'] ?? 'active').toString().toLowerCase();
          
          String timeAgo = '';
          final createdAt = m['created_at']?.toString() ?? '';
          if (createdAt.isNotEmpty) {
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
          }
          if (mName.isNotEmpty) {
            parsedMembers.add(TeamMember(
              userId: mUserId,
              name: mName,
              role: mRole,
              status: mStatus,
              timeAgo: timeAgo,
            ));
          }
        } else {
          parsedMembers.add(TeamMember(
            userId: '',
            name: m.toString(),
            role: 'Member',
            status: 'active',
          ));
        }
      }

      if (cleanUid != null) {
        for (var m in memberList) {
          bool match = false;
          String mStatus = '';
          if (m is Map) {
            final mUserId = m['user_id']?.toString()?.trim() ?? 
                            m['user']?['id']?.toString()?.trim() ?? 
                            m['id']?.toString()?.trim();
                            
            if (mUserId != null && mUserId.isNotEmpty) {
              match = mUserId == cleanUid || (numericUid != null && mUserId == numericUid);
            }
            if (match) {
              mStatus = (m['member_status'] ?? m['status'] ?? m['membership_status'] ?? '').toString().toLowerCase();
            }
          } else {
            final mStr = m.toString().trim();
            match = mStr == cleanUid || (numericUid != null && mStr == numericUid);
          }

          if (match) {
            memberFound = true;
            if (['approved', 'accepted', 'active', 'diterima', 'setuju'].contains(mStatus)) {
              isAcceptedByList = true;
            }
          }
        }
      }

      // Last resort: name matching
      if (!memberFound && cleanUid != null && AuthService.loggedInUserName != null) {
        final myName = AuthService.loggedInUserName!.toLowerCase().trim();
        memberFound = names.any((n) => n.toLowerCase().trim() == myName);
      }
    }
    final isOwner = cleanUid != null && (createdBy == cleanUid || (numericUid != null && createdBy == numericUid));
    return TeamModel(
      id: json['team_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['team_name'] ?? json['name'] ?? 'Tanpa Nama Tim',
      lombaName: json['competition_name'] ?? json['lomba_name'] ?? 'Tanpa Nama Lomba',
      maxMembers: json['max_member'] != null ? int.tryParse(json['max_member'].toString()) ?? 0 : 0,
      description: json['description'] ?? '',
      status: json['status']?.toString() ?? 'Open',
      joinedMembers: json['current_member_count'] != null ? int.tryParse(json['current_member_count'].toString()) ?? 0 : 0,
      createdBy: createdBy,
      isOwner: isOwner,
      isMember: isOwner || memberFound,
      isAcceptedMember: isOwner || isAcceptedRaw || isAcceptedByList,
      isLiked: json['is_liked'] == true || json['is_liked'] == 1 || json['liked_by_user'] == true,
      memberNames: names,
      members: parsedMembers,
    );
  }
}
