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
  final List<String> memberNames;

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
    this.memberNames = const [],
  });

  factory TeamModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    // Backend view_teams returns leader_id, while teams table has created_by
    final createdBy = json['created_by']?.toString() ?? json['leader_id']?.toString() ?? '';
    final members = json['members'];
    List<String> names = [];
    bool memberFound = false;
    if (members is List) {
      names = members
          .map((m) => (m['name'] ?? m['user_name'] ?? '').toString())
          .where((n) => n.isNotEmpty)
          .toList();
      if (currentUserId != null) {
        memberFound = members.any((m) {
          final uid1 = m['user_id']?.toString();
          final uid2 = m['id']?.toString();
          final uid3 = m['member_id']?.toString();
          final nestedUid1 = m['user']?['id']?.toString();
          final nestedUid2 = m['user']?['user_id']?.toString();
          return uid1 == currentUserId || 
                 uid2 == currentUserId || 
                 uid3 == currentUserId || 
                 nestedUid1 == currentUserId || 
                 nestedUid2 == currentUserId;
        });
      }
    }
    final isOwner = currentUserId != null && createdBy == currentUserId;
    return TeamModel(
      id: json['team_id']?.toString() ?? '',
      name: json['team_name'] ?? 'Tanpa Nama Tim',
      lombaName: json['competition_name'] ?? 'Tanpa Nama Lomba',
      maxMembers: json['max_member'] != null ? int.tryParse(json['max_member'].toString()) ?? 0 : 0,
      description: json['description'] ?? '',
      status: json['status']?.toString() ?? 'Open',
      joinedMembers: json['current_member_count'] != null ? int.tryParse(json['current_member_count'].toString()) ?? 0 : 0,
      createdBy: createdBy,
      isOwner: isOwner,
      isMember: isOwner || memberFound,
      memberNames: names,
    );
  }
}

