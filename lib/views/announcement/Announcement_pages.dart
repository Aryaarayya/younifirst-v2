import 'package:flutter/material.dart';
import 'package:younifirst_app/models/Announcement_model.dart';
import 'package:younifirst_app/services/api/announcement_api_service.dart';
import 'package:younifirst_app/services/api/event_api_service.dart';
import 'package:younifirst_app/services/input/notification_service.dart';
import 'package:younifirst_app/views/announcement/AnnouncementDetail_pages.dart';
import 'package:younifirst_app/views/event/EventDetail_pages.dart';
import 'package:younifirst_app/views/team/TeamDetail_pages.dart';
import 'package:younifirst_app/views/barang/BarangDetail_pages.dart';
import 'package:younifirst_app/services/api/lostandfound_api_service.dart';
import 'package:provider/provider.dart';
import 'package:younifirst_app/viewmodels/announcement_viewmodel.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({Key? key}) : super(key: key);

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementViewModel>().loadAnnouncements();
      NotificationService.markAnnouncementsAsRead();
      NotificationService.markInAppNotifsAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        foregroundColor: Theme.of(context).iconTheme.color,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {},
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Consumer<AnnouncementViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return _buildSkeleton();
          }
          if (viewModel.error != null) {
            return _buildError(viewModel);
          }
          if (viewModel.announcements.isEmpty) {
            return _buildEmpty();
          }

          return RefreshIndicator(
            onRefresh: viewModel.loadAnnouncements,
            color: const Color(0xFF3D5AFE),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                for (final entry in viewModel.groupedAnnouncements.entries) ...[
                  _buildSectionHeader(entry.key),
                  for (final item in entry.value) _buildNotifCard(item, viewModel),
                ]
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54,
        ),
      ),
    );
  }

  // ─── Notification Card ────────────────────────────────────────────────────
  bool isEventNotification(AnnouncementModel item) {
    final cat = item.category?.toLowerCase() ?? 'umum';
    if (cat == 'event' || cat == 'pengajuan_event') return true;
    final title = item.title.toLowerCase();
    final content = item.content.toLowerCase();
    if (title.contains('event') || content.contains('event')) return true;
    return false;
  }

  bool isTeamNotification(AnnouncementModel item) {
    final cat = item.category?.toLowerCase() ?? 'umum';
    if (cat == 'team' || cat == 'pengajuan_tim') return true;
    final title = item.title.toLowerCase();
    final content = item.content.toLowerCase();
    if (title.contains('tim') || title.contains('team') || content.contains('tim') || content.contains('team')) return true;
    return false;
  }

  bool isBarangNotification(AnnouncementModel item) {
    final cat = item.category?.toLowerCase() ?? 'umum';
    if (cat == 'barang') return true;
    if (item.targetId != null && item.targetId!.startsWith('LF')) return true;
    final title = item.title.toLowerCase();
    final content = item.content.toLowerCase();
    if (title.contains('barang') || content.contains('barang') || title.contains('lost') || content.contains('lost')) return true;
    return false;
  }

  String getEffectiveCategory(AnnouncementModel item) {
    if (isEventNotification(item)) return 'event';
    if (isTeamNotification(item)) return 'team';
    if (isBarangNotification(item)) return 'barang';
    return item.category?.toLowerCase() ?? 'umum';
  }

  bool isApprovedOrSuccess(AnnouncementModel item) {
    if (item.status?.toLowerCase() == 'confirmed' || item.status?.toLowerCase() == 'approved') return true;
    final content = item.content.toLowerCase();
    final title = item.title.toLowerCase();
    return content.contains('setuju') || content.contains('terima') || content.contains('berhasil') ||
           content.contains('approved') || content.contains('success') ||
           title.contains('setuju') || title.contains('terima') || title.contains('berhasil') ||
           title.contains('approved') || title.contains('success');
  }

  bool isRejectedOrFail(AnnouncementModel item) {
    if (item.status?.toLowerCase() == 'rejected' || item.status?.toLowerCase() == 'failed') return true;
    final content = item.content.toLowerCase();
    final title = item.title.toLowerCase();
    return content.contains('tolak') || content.contains('gagal') ||
           content.contains('rejected') || content.contains('failed') ||
           title.contains('tolak') || title.contains('gagal') ||
           title.contains('rejected') || title.contains('failed');
  }

  Widget _buildAvatar(AnnouncementModel item) {
    final cat = getEffectiveCategory(item);
    
    if (isApprovedOrSuccess(item)) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFFE8EAFF),
        child: const Text('🎉', style: TextStyle(fontSize: 22)),
      );
    }
    
    if (isRejectedOrFail(item)) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFFE8EAFF),
        child: const Text('😔', style: TextStyle(fontSize: 22)),
      );
    }

    if (cat == 'comment' || cat == 'reply') {
      if (item.userAvatar != null && item.userAvatar!.isNotEmpty) {
        String avatarUrl = item.userAvatar!;
        if (!avatarUrl.startsWith('http')) {
          avatarUrl = LostFoundApiService.getFullUrl(avatarUrl);
        }
        return CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(avatarUrl),
          backgroundColor: Colors.grey.shade200,
        );
      } else {
        return CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF3D5AFE),
          child: const Icon(Icons.person, color: Colors.white, size: 24),
        );
      }
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE8EAFF),
      child: const Icon(Icons.campaign, color: Color(0xFF3D5AFE), size: 24),
    );
  }

  Widget _buildRightThumbnail(AnnouncementModel item) {
    final cat = getEffectiveCategory(item);
    
    if (cat == 'barang' && item.postImage != null && item.postImage!.isNotEmpty) {
      String imageUrl = item.postImage!;
      if (!imageUrl.startsWith('http')) {
        imageUrl = LostFoundApiService.getFullUrl(imageUrl);
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackRightIcon(cat),
        ),
      );
    }
    
    return _buildFallbackRightIcon(cat);
  }

  Widget _buildFallbackRightIcon(String cat) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _categoryColor(cat).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          _categoryIcon(cat),
          color: _categoryColor(cat),
          size: 26,
        ),
      ),
    );
  }

  Widget _buildRichContent(AnnouncementModel item) {
    final text = item.content.isNotEmpty ? item.content : item.title;
    final List<String> boldKeywords = [];
    
    if (item.userNama != null && item.userNama!.isNotEmpty && item.userNama != 'Sistem' && item.userNama != 'Sistem Notifikasi') {
      boldKeywords.add(item.userNama!);
    }

    final quoteRegex = RegExp(r'["\u201c\u201d]([^"\u201c\u201d]+)["\u201c\u201d]');
    final matches = quoteRegex.allMatches(text);
    for (final match in matches) {
      if (match.group(1) != null) {
        boldKeywords.add(match.group(1)!);
      }
    }

    final teamMatch = RegExp(r'[Pp]engajuan tim ([A-Za-z0-9_ ]+) Anda');
    final tMatch = teamMatch.firstMatch(text);
    if (tMatch != null && tMatch.group(1) != null) {
      boldKeywords.add(tMatch.group(1)!);
    }
    
    final eventMatch = RegExp(r'[Pp]engajuan event ([A-Za-z0-9_ ]+) Anda');
    final eMatch = eventMatch.firstMatch(text);
    if (eMatch != null && eMatch.group(1) != null) {
      boldKeywords.add(eMatch.group(1)!);
    }

    if (boldKeywords.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
      );
    }

    boldKeywords.sort((a, b) => b.length.compareTo(a.length));
    
    List<TextSpan> spans = [];
    String currentText = text;
    bool foundKeyword = true;
    
    while (foundKeyword) {
      foundKeyword = false;
      int earliestIndex = -1;
      String matchedKeyword = "";
      
      for (final kw in boldKeywords) {
        final idx = currentText.indexOf(kw);
        if (idx != -1) {
          if (earliestIndex == -1 || idx < earliestIndex) {
            earliestIndex = idx;
            matchedKeyword = kw;
            foundKeyword = true;
          }
        }
      }
      
      if (foundKeyword) {
        if (earliestIndex > 0) {
          spans.add(TextSpan(text: currentText.substring(0, earliestIndex)));
        }
        spans.add(TextSpan(
          text: matchedKeyword,
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87),
        ));
        currentText = currentText.substring(earliestIndex + matchedKeyword.length);
      }
    }
    
    if (currentText.isNotEmpty) {
      spans.add(TextSpan(text: currentText));
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87, height: 1.4),
        children: spans,
      ),
    );
  }

  Widget _buildNotifCard(AnnouncementModel item, AnnouncementViewModel viewModel) {
    final category = getEffectiveCategory(item);
    final isNew = item.isNew;

    return InkWell(
      onTap: () async {
        final targetId = item.targetId;
        if (isEventNotification(item) && targetId != null && targetId.isNotEmpty) {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => EventDetailPage(eventId: targetId)),
          );
          if (result == true) viewModel.loadAnnouncements();
        } else if (isTeamNotification(item) && targetId != null && targetId.isNotEmpty) {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => TeamDetailPage(teamId: targetId)),
          );
          if (result == true) viewModel.loadAnnouncements();
        } else if (isBarangNotification(item) && targetId != null && targetId.isNotEmpty) {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => BarangDetailPage(lostFoundId: targetId)),
          );
          if (result == true) viewModel.loadAnnouncements();
        } else {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => AnnouncementDetailPage(announcement: item)),
          );
          if (result == true) viewModel.loadAnnouncements();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isNew 
              ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E2244) : const Color(0xFFF0F3FF)) 
              : Theme.of(context).cardColor,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.black12, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread Indicator (Blue Dot) on the far left
            if (isNew)
              Padding(
                padding: const EdgeInsets.only(top: 18, right: 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3D5AFE),
                    shape: BoxShape.circle,
                  ),
                ),
              )
            else
              const SizedBox(width: 16),

            // Avatar
            _buildAvatar(item),
            
            const SizedBox(width: 14),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _categoryLabel(category),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _buildRichContent(item),
                  const SizedBox(height: 5),
                  Text(
                    item.timeAgo,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),

            // Right Thumbnail/Icon
            _buildRightThumbnail(item),
          ],
        ),
      ),
    );
  }

  // ─── Loading Skeleton ─────────────────────────────────────────────────────
  Widget _buildSkeleton() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 12,
                      width: 120,
                      color: Colors.grey.shade200),
                  const SizedBox(height: 6),
                  Container(
                      height: 12,
                      width: double.infinity,
                      color: Colors.grey.shade200),
                  const SizedBox(height: 4),
                  Container(
                      height: 10,
                      width: 60,
                      color: Colors.grey.shade100),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 52,
              height: 52,
              color: Colors.grey.shade200,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error state ──────────────────────────────────────────────────────────
  Widget _buildError(AnnouncementViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Gagal memuat notifikasi',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: viewModel.loadAnnouncements,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          )
        ],
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none,
              size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Belum ada pengumuman',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.black54),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pengumuman baru akan muncul di sini',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Color _categoryColor(String cat) {
    switch (cat) {
      case 'event': return Colors.orange;
      case 'team': return Colors.green;
      case 'pengajuan_tim': return Colors.teal;
      case 'barang': return Colors.purple;
      case 'pengajuan_event': return Colors.blue;
      case 'comment': return const Color(0xFF3D5AFE);
      case 'reply': return const Color(0xFF00BCD4);
      default: return const Color(0xFF3D5AFE);
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'event': return Icons.calendar_today;
      case 'team': return Icons.group;
      case 'pengajuan_tim': return Icons.group_add;
      case 'barang': return Icons.inventory_2_outlined;
      case 'pengajuan_event': return Icons.hourglass_top;
      case 'comment': return Icons.chat_bubble_outline;
      case 'reply': return Icons.reply_rounded;
      default: return Icons.campaign;
    }
  }

  String _categoryLabel(String cat) {
    switch (cat) {
      case 'event': return 'Pengumuman Event';
      case 'team': return 'Pengumuman Tim';
      case 'pengajuan_tim': return 'Pengajuan Tim Dikirim';
      case 'barang': return 'Pengumuman Barang';
      case 'pengajuan_event': return 'Menunggu Persetujuan';
      case 'comment': return 'Komentar Baru 💬';
      case 'reply': return 'Balasan Komentar 💬';
      default: return 'Pengumuman Umum';
    }
  }
}
