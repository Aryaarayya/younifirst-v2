import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:younifirst_app/viewmodels/settings_viewmodel.dart';

class PengaturanPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Pengaturan'),
        centerTitle: true,
      ),
      body: Consumer<SettingsViewModel>(
        builder: (context, settings, child) {
          return ListView(
            padding: EdgeInsets.all(24),
            children: [
              // MODE TAMPILAN
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Mode Tampilan",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Pilih tampilan aplikasi sesuai preferensi Anda.",
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildThemeCard(
                            context,
                            "Terang",
                            Icons.wb_sunny_outlined,
                            settings.themeMode == ThemeMode.light,
                            () => settings.setThemeMode(ThemeMode.light),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildThemeCard(
                            context,
                            "Gelap",
                            Icons.nightlight_outlined,
                            settings.themeMode == ThemeMode.dark,
                            () => settings.setThemeMode(ThemeMode.dark),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // UKURAN TEKS
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ukuran Teks",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sesuaikan ukuran teks agar lebih nyaman dibaca.",
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        const Text("A-", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: const Color(0xFF3D5AF1),
                              inactiveTrackColor: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.grey[300],
                              thumbColor: const Color(0xFF3D5AF1),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: settings.textScaleFactor,
                              min: 0.8,
                              max: 1.2,
                              divisions: 2, // 0.8 (Kecil), 1.0 (Sedang), 1.2 (Besar)
                              onChanged: (value) {
                                  settings.setTextScaleFactor(value);
                              },
                            ),
                          ),
                        ),
                        const Text("A+", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Center(
                      child: Text(
                        settings.textScaleFactor == 0.8 ? "Kecil" : (settings.textScaleFactor == 1.2 ? "Besar" : "Sedang"),
                        style: TextStyle(color: Color(0xFF3D5AF1), fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),


            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, String title, IconData icon, bool isSelected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3D5AF1)
                : (isDark ? Colors.grey[800]! : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: isSelected
                      ? const Color(0xFF3D5AF1)
                      : (isDark ? Colors.grey[400] : Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? const Color(0xFF3D5AF1)
                        : (isDark ? Colors.grey[300] : Colors.grey[800]),
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: -16,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3D5AF1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }


}
