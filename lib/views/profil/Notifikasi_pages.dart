import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings_viewmodel.dart';

class NotifikasiPage extends StatelessWidget {
  const NotifikasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengaturan Notifikasi',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.titleTextStyle?.color ?? Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: Consumer<SettingsViewModel>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // Info card
              _buildInfoCard(context),
              const SizedBox(height: 16),

              // Notification toggle cards container
              _buildToggleGroup(context, settings),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'Pilih jenis notifikasi yang ingin Anda terima. Anda tetap dapat melihat notifikasi di dalam Aplikasi',
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.grey[300] : const Color(0xFF444444),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildToggleGroup(BuildContext context, SettingsViewModel settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildNotifTile(
            context,
            title: 'Event',
            subtitle: 'Event baru dan update',
            value: settings.notifEvent,
            onChanged: (val) => settings.setNotifEvent(val),
            isFirst: true,
            isLast: false,
          ),
          _buildDivider(context),
          _buildNotifTile(
            context,
            title: 'Tim',
            subtitle: 'Aktivitas tim dan grup yang diikuti',
            value: settings.notifTim,
            onChanged: (val) => settings.setNotifTim(val),
            isFirst: false,
            isLast: false,
          ),
          _buildDivider(context),
          _buildNotifTile(
            context,
            title: 'Lost and Found',
            subtitle: 'Postingan dan komentar lost and found',
            value: settings.notifLostFound,
            onChanged: (val) => settings.setNotifLostFound(val),
            isFirst: false,
            isLast: false,
          ),
          _buildDivider(context),
          _buildNotifTile(
            context,
            title: 'Announcement',
            subtitle: 'Announcement/pemberitahuan baru',
            value: settings.notifAnnouncement,
            onChanged: (val) => settings.setNotifAnnouncement(val),
            isFirst: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _buildNotifTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isFirst,
    required bool isLast,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : const Color(0xFF888888),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF3D5AFE),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: isDark ? Colors.grey[800] : const Color(0xFFDDDDDD),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
