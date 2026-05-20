import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────

class _FaqItem {
  final String question;
  final String answer;
  final String category; // 'semua' | 'event' | 'tim' | 'lostfound'

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}

// ─── FAQ Data ─────────────────────────────────────────────────────────────────

const List<_FaqItem> _allFaqs = [
  _FaqItem(
    question: 'Apa itu Younifirst?',
    answer:
        'Younifirst adalah platform yang membantu mahasiswa menemukan event kampus, membangun tim, melaporkan barang hilang, dan mendapatkan notifikasi penting dalam satu aplikasi.',
    category: 'semua',
  ),
  _FaqItem(
    question: 'Bagaimana cara menggunakan fitur Event Center?',
    answer:
        'Buka tab "Event" di menu bawah, lalu Anda dapat melihat daftar event yang tersedia. Tekan event yang diminati untuk melihat detail dan mendaftarkan diri.',
    category: 'event',
  ),
  _FaqItem(
    question: 'Apa itu Team Builder dan bagaimana cara kerjanya?',
    answer:
        'Team Builder membantu Anda menemukan rekan tim untuk proyek atau kompetisi. Buat postingan tim, tentukan kebutuhan anggota, dan tunggu lamaran masuk.',
    category: 'tim',
  ),
  _FaqItem(
    question: 'Bagaimana cara melaporkan barang di Lost & Found?',
    answer:
        'Buka tab "Barang", lalu pilih "Laporkan Barang Hilang" atau "Laporkan Barang Temuan". Isi detail dan unggah foto barang untuk memudahkan proses pencarian.',
    category: 'lostfound',
  ),
  _FaqItem(
    question: 'Apa saja notifikasi yang akan saya terima?',
    answer:
        'Anda dapat mengatur jenis notifikasi di Pengaturan Notifikasi, meliputi notifikasi Event, Tim, Lost & Found, dan Pengumuman dari admin.',
    category: 'semua',
  ),
  _FaqItem(
    question: 'Apakah saya harus login untuk menggunakan Younifirst?',
    answer:
        'Ya, login diperlukan untuk mengakses semua fitur Younifirst. Gunakan akun yang telah terdaftar atau daftarkan diri terlebih dahulu.',
    category: 'semua',
  ),
  _FaqItem(
    question: 'Apakah Younifirst gratis digunakan?',
    answer:
        'Ya, Younifirst sepenuhnya gratis untuk seluruh mahasiswa. Tidak ada biaya berlangganan maupun fitur berbayar.',
    category: 'semua',
  ),
  _FaqItem(
    question: 'Bagaimana jika saya tidak menemukan event atau tim yang cocok?',
    answer:
        'Anda dapat membuat event atau postingan tim sendiri. Gunakan fitur buat event/tim di halaman masing-masing fitur.',
    category: 'event',
  ),
  _FaqItem(
    question: 'Apakah data saya aman di Younifirst?',
    answer:
        'Tentu saja. Kami menggunakan enkripsi standar industri untuk melindungi semua data pribadi dan aktivitas pengguna kami.',
    category: 'semua',
  ),
  _FaqItem(
    question: 'Siapa yang bisa saya hubungi jika mengalami masalah?',
    answer:
        'Anda dapat menghubungi tim support kami melalui tombol "Hubungi Support" di bagian bawah halaman ini. Tim kami siap membantu 24 jam.',
    category: 'semua',
  ),
];

// ─── Category Model ───────────────────────────────────────────────────────────

class _Category {
  final String key;
  final String label;
  final IconData icon;

  const _Category({required this.key, required this.label, required this.icon});
}

const List<_Category> _categories = [
  _Category(key: 'semua', label: 'Semua', icon: Icons.check_circle_rounded),
  _Category(key: 'event', label: 'Event', icon: Icons.calendar_today_outlined),
  _Category(key: 'tim', label: 'Tim', icon: Icons.group_outlined),
  _Category(
      key: 'lostfound', label: 'Lost and Found', icon: Icons.search_outlined),
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class PusatBantuanPage extends StatefulWidget {
  const PusatBantuanPage({super.key});

  @override
  State<PusatBantuanPage> createState() => _PusatBantuanPageState();
}

class _PusatBantuanPageState extends State<PusatBantuanPage> {
  static const _blue = Color(0xFF3D5AFE);
  static const _bgColor = Color(0xFFF0F2F8);
  static const _whatsappNumber = '6285812749419';

  String _selectedCategory = 'semua';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  // Which FAQ items are expanded
  final Set<int> _expandedIndices = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_FaqItem> get _filteredFaqs {
    return _allFaqs.where((faq) {
      final matchCategory = _selectedCategory == 'semua' ||
          faq.category == _selectedCategory ||
          faq.category == 'semua';
      final matchSearch = _searchQuery.isEmpty ||
          faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq.answer.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  Future<void> _launchWhatsApp() async {
    const message = 'Halo Younifirst Support, saya butuh bantuan...';
    final uri = Uri.parse(
        'https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent(message)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tidak dapat membuka WhatsApp'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'younifirst@gmail.com',
      query: 'subject=Bantuan Younifirst',
    );
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tidak dapat membuka aplikasi email'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final faqs = _filteredFaqs;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pusat Bantuan',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),

      // ── FAB Hubungi Support ──────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: _launchWhatsApp,
        backgroundColor: _blue,
        shape: const CircleBorder(),
        child: const Icon(Icons.headset_mic_outlined,
            color: Colors.white, size: 24),
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // ── Search Bar ─────────────────────────────────────────────────
            _buildSearchBar(),
            const SizedBox(height: 14),

            // ── Category Chips ─────────────────────────────────────────────
            _buildCategoryChips(),
            const SizedBox(height: 14),

            // ── FAQ List ───────────────────────────────────────────────────
            if (faqs.isEmpty)
              _buildEmptyState()
            else
              ...List.generate(faqs.length, (i) {
                return _buildFaqCard(faqs[i], i);
              }),

            const SizedBox(height: 16),

            // ── Contact Support Card ───────────────────────────────────────
            _buildContactCard(),
            const SizedBox(height: 16),

            // ── Quick Links ────────────────────────────────────────────────
            _buildQuickLink(
              icon: Icons.help_outline_rounded,
              label: 'Bantuan & Panduan',
              onTap: _launchWhatsApp,
            ),
            _buildQuickLink(
              icon: Icons.flag_outlined,
              label: 'Laporkan Masalah',
              onTap: _launchEmail,
            ),
            _buildQuickLink(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Kirim Saran',
              onTap: _launchEmail,
            ),

            const SizedBox(height: 24),

            // ── Footer ─────────────────────────────────────────────────────
            const Center(
              child: Text(
                '© 2026 Younifirst Team',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFAAAAAA),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Cari bantuan atau topik...',
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFAAAAAA), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFFAAAAAA), size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = cat.key;
                  _expandedIndices.clear();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3D5AFE) : Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3D5AFE)
                        : const Color(0xFFDDDDDD),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      cat.icon,
                      size: 15,
                      color: isSelected ? Colors.white : const Color(0xFF555555),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color:
                            isSelected ? Colors.white : const Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFaqCard(_FaqItem faq, int index) {
    final isExpanded = _expandedIndices.contains(index);
    final number = (index + 1).toString().padLeft(2, '0');

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedIndices.remove(index);
          } else {
            _expandedIndices.add(index);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Number badge
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      number,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D5AFE),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Question
                  Expanded(
                    child: Text(
                      faq.question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Arrow
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF888888),
                      size: 22,
                    ),
                  ),
                ],
              ),
              // Answer
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 42),
                  child: Text(
                    faq.answer,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                      height: 1.6,
                    ),
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFCCCCCC)),
          SizedBox(height: 12),
          Text(
            'Tidak ada hasil ditemukan',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFFAAAAAA),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Coba kata kunci lain atau pilih kategori berbeda',
            style: TextStyle(fontSize: 13, color: Color(0xFFCCCCCC)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Illustration placeholder
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF3D5AFE).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Color(0xFF3D5AFE),
                  size: 40,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Butuh bantuan lebih lanjut?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tim kami siap membantu menjawab pertanyaanmu',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF555555),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _launchWhatsApp,
              icon: const Icon(Icons.headset_mic_outlined,
                  color: Colors.white, size: 18),
              label: const Text(
                'Hubungi Support',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D5AFE),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF3D5AFE), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFBBBBBB), size: 20),
          ],
        ),
      ),
    );
  }
}
