import 'package:flutter/material.dart';
import 'package:younifirst_app/models/lost_found_model.dart';
import 'package:younifirst_app/models/comment_model.dart';
import 'package:younifirst_app/services/api/lostandfound_api_service.dart';
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:younifirst_app/services/input/notification_service.dart';
import 'package:younifirst_app/utils/profanity_filter.dart';
import 'package:younifirst_app/widgets/notification_bell.dart';
import 'BarangHilang_pages.dart';
import 'package:provider/provider.dart';
import 'package:younifirst_app/viewmodels/barang_viewmodel.dart';
import 'package:younifirst_app/viewmodels/profil_viewmodel.dart';
import 'package:younifirst_app/services/api/lostandfound_api_service.dart';

class BarangPage extends StatefulWidget {
  @override
  _BarangPageState createState() => _BarangPageState();
}

class _BarangPageState extends State<BarangPage> {
  // Real-time search variables
  final TextEditingController _searchController = TextEditingController();
  int _unreadNotificationCount = 0;
  
  @override
  void initState() {
    super.initState();
    _refreshNotificationCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BarangViewModel>().fetchBarang();
    });
  }

  void _refreshNotificationCount() async {
    int count = await NotificationService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadNotificationCount = count;
      });
    }
  }

  void _fetchData() {
    context.read<BarangViewModel>().fetchBarang();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Consumer<BarangViewModel>(
        builder: (context, viewModel, child) {
          return RefreshIndicator(
            onRefresh: () async {
              viewModel.fetchBarang();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Stack(
                children: [
                  // Blue Background Top
                  Container(
                    height: 250,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3D5AFE),
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildSearchBar(viewModel),
                        const SizedBox(height: 16),
                        _buildFilterRow(viewModel),
                        const SizedBox(height: 24),
                        _buildBarangList(viewModel),
                        const SizedBox(height: 80), // Padding for FAB
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BarangHilangPage(),
            ),
          );
          if (result == true) {
            _fetchData();
            _refreshNotificationCount();
          }
        },
        backgroundColor: const Color(0xFF3D5AFE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(  
                'assets/images/logo_putih.png',
                width: 35,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, color: Colors.white, size: 35),
              ),
              const SizedBox(width: 12),
              const Text(
                "Barang",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
          NotificationBell(iconColor: Colors.white),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BarangViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => viewModel.setSearchQuery(value),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Temukan barang hilang...",
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            suffixIcon: viewModel.searchQuery.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _searchController.clear();
                    viewModel.clearSearch();
                  },
                )
              : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(BarangViewModel viewModel) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          ...List.generate(viewModel.filters.length, (index) {
            bool isSelected = viewModel.selectedFilterIndex == index;
            IconData iconData;
            if (index == 0) {
              iconData = Icons.check_circle;
            } else if (index == 1) {
              iconData = Icons.inventory_2_outlined;
            } else {
              iconData = Icons.inventory_outlined;
            }

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  viewModel.setFilterIndex(index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        iconData,
                        size: 16,
                        color: isSelected ? const Color(0xFF3D5AFE) : Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        viewModel.filters[index],
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF3D5AFE) : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: const [
                Icon(Icons.insert_drive_file_outlined, color: Colors.white, size: 20),
                SizedBox(width: 4),
                Icon(Icons.sort, color: Colors.white, size: 20),
              ],
            ),
          )
        ]
      ),
    );
  }

  Widget _buildBarangList(BarangViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: viewModel.isLoading 
        ? const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(color: Colors.white),
          ))
        : viewModel.allData.isEmpty
          ? _buildStaticFallbackList(viewModel)
          : viewModel.filteredData.isEmpty
            ? _buildNoResultsFound()
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: viewModel.filteredData.length,
                itemBuilder: (context, index) {
                  return _buildBarangCard(viewModel.filteredData[index]);
                },
              ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.search_off, size: 80, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            "Hasil tidak ditemukan",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Coba kata kunci lain atau filter berbeda",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Fallback List statis agar UI tetap bisa dilihat sesuai screenshot
  // meskipun backend API tidak tersedia / error
  Widget _buildStaticFallbackList(BarangViewModel viewModel) {
    final List<LostFoundModel> dummyData = [
      LostFoundModel(
        lostfoundId: 'LF00000001',
        userName: 'Rafayel Qi',
        userAvatar: 'https://images.unsplash.com/photo-1599566150163-29194dcaad36?auto=format&fit=crop&q=80&w=150',
        type: 'Ditemukan',
        itemName: 'Earphone Putih',
        location: 'Gedung TI Politeknik Negeri Jember',
        description: 'Earphone ditemukan di Gedung TI Lantai 3 Ruangan 3 sekitar jam 12 siang tadi. aku pegang dulu bentar kalau ga ada info atau reach out sampe jam 4 aku bawa',
        imageUrl: 'https://images.unsplash.com/photo-1605464315542-bda3e2f4e605?auto=format&fit=crop&q=80&w=400',
        createdAt: 'Hari ini • 25 mnt yang lalu',
        commentsCount: 0,
      ),
      LostFoundModel(
        lostfoundId: 'LF00000002',
        userName: 'rona_naa',
        userAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=150',
        type: 'Hilang',
        itemName: 'Dompet Soft Pink Cream',
        location: 'Teras JTI Politeknik Negeri Jember',
        description: 'HELP!! URGENT!! Dompet aku hilang sepertinya jatuh habis dari teras jti bagi yang melihat atau menemukan tolong segera kontak nomor ini "1234567890"',
        imageUrl: 'https://images.unsplash.com/photo-1628191010210-a59de33e5941?auto=format&fit=crop&q=80&w=400',
        createdAt: 'Hari ini • 1 jam yang lalu',
        commentsCount: 12,
      ),
      LostFoundModel(
        lostfoundId: 'LF00000003',
        userName: 'Xavier Shen',
        userAvatar: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&q=80&w=150',
        type: 'Hilang',
        itemName: 'Kotak Pensil Hitam + KTM',
        location: 'Gedung TI Politeknik Negeri Jember',
        description: 'Balik pulang kerasa ada yng janggal ternyata kotak pensilku ketinggalan huhu.. mana ada KTM ku disana atas nama "Xavier Shen Prodi Teknik Informatika" anyon',
        imageUrl: null, 
        createdAt: 'Kemarin • 1 hari yang lalu',
        commentsCount: 22,
      ),
    ];

    String query = viewModel.searchQuery.toLowerCase();
    List<LostFoundModel> displayed = dummyData.where((item) {
      // Filter by type
      bool matchesFilter = true;
      if (viewModel.selectedFilterIndex != 0) {
        matchesFilter = item.type == viewModel.filters[viewModel.selectedFilterIndex];
      }

      // Filter by search query
      bool matchesSearch = item.itemName.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query) ||
          item.userName.toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList();

    if (displayed.isEmpty && (viewModel.searchQuery.isNotEmpty || viewModel.selectedFilterIndex != 0)) {
      return _buildNoResultsFound();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayed.length,
      itemBuilder: (context, index) {
        return _buildBarangCard(displayed[index]);
      },
    );
  }

  Widget _buildBarangCard(LostFoundModel item) {
    bool isDitemukan = item.type == 'Ditemukan';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3)
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: item.userAvatar != null ? NetworkImage(item.userAvatar!) : null,
                child: item.userAvatar == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      item.createdAt ?? 'Baru saja',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opsi ditekan')));
                },
                child: const Icon(Icons.more_horiz, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Image / Media
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.imageUrl!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(height: 250, width: double.infinity, color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey)),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDitemukan ? const Color(0xFF3D5AFE) : const Color(0xFF3D5AFE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.type,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          else 
            // Jika tidak ada gambar, label Hilang/Ditemukan tetap di kanan atas
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isDitemukan ? const Color(0xFF3D5AFE) : const Color(0xFF3D5AFE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.type,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
          const SizedBox(height: 16),
          
          // Title / Item Name
          Text(
            item.itemName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF3D5AFE)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.location,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF3D5AFE), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Description
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
              children: [
                TextSpan(text: '${item.description} '),
                TextSpan(
                  text: 'selengkapnya...',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Komentar Field
          GestureDetector(
            onTap: () {
              _showCommentSheet(context, item.lostfoundId);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Text("Beri Komentar...", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const Spacer(),
                  const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.black87),
                  if (item.commentsCount > 0) ...[
                    const SizedBox(width: 4),
                    Text(item.commentsCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ]
                ],
              ),
            ),
          ),

          // Tandai Postingan Selesai (Hanya jika ini adalah postingan user tersebut)
          if (!item.isCompleted && item.userId == AuthService.loggedInUserId) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _showFinishConfirmation(context, item);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3D5AFE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: const Color(0xFFEEF2FF),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Tandai Postingan Selesai', style: TextStyle(color: Color(0xFF3D5AFE), fontWeight: FontWeight.bold)),
              ),
            )
          ]
        ],
      ),
    );
  }

  void _showCommentSheet(BuildContext context, String lostFoundId) {
    TextEditingController commentController = TextEditingController();
    bool isSending = false;
    CommentModel? replyingTo;
    CommentModel? editingComment;
    Set<String> expandedCommentIds = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                   // Handle bar
                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 16),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text("Komentar postingan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              context.read<BarangViewModel>().allData.firstWhere((element) => element.lostfoundId == lostFoundId).commentsCount.toString(),
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.sort, color: Colors.black87),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Comment List
                  Expanded(
                    child: FutureBuilder<List<CommentModel>>(
                      future: LostFoundApiService.getComments(lostFoundId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) return Center(child: Text('Gagal: ${snapshot.error}'));
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildEmptyComments();
                        }

                        // Organize comments into threads
                        final allComments = snapshot.data!;
                        final Map<String, CommentModel> commentMap = {for (var c in allComments) c.id: c};
                        final List<CommentModel> rootComments = [];
                        
                        for (var c in allComments) {
                          if (c.parentId != null && commentMap.containsKey(c.parentId)) {
                            commentMap[c.parentId]!.replies.add(c);
                          } else {
                            rootComments.add(c);
                          }
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          itemCount: rootComments.length,
                          itemBuilder: (context, index) {
                            return _buildThreadedComment(
                              rootComments[index], 
                              setModalState,
                              expandedCommentIds,
                              () => _fetchData(),
                              (comment) {
                                setModalState(() {
                                  replyingTo = comment;
                                  editingComment = null;
                                  commentController.text = "";
                                });
                              },
                              (comment) {
                                setModalState(() {
                                  editingComment = comment;
                                  replyingTo = null;
                                  commentController.text = comment.commentTextOnly;
                                });
                              }
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Input Field Section
                  _buildCommentInput(
                    commentController, 
                    isSending, 
                    replyingTo, 
                    editingComment,
                    () => setModalState(() { replyingTo = null; editingComment = null; commentController.clear(); }),
                    () async {
                      if (commentController.text.trim().isEmpty) return;
                      
                      // ── PROFANITY FILTER CHECK ──
                      List<String> badWords = ProfanityFilter.check(commentController.text);
                      if (badWords.isNotEmpty) {
                        _showProfanityWarning(context, badWords);
                        return;
                      }
                      // ────────────────────────────

                      setModalState(() => isSending = true);
                      try {
                        bool success;
                        if (editingComment != null) {
                          success = await LostFoundApiService.updateComment(editingComment!.id, commentController.text);
                        } else {
                          success = await LostFoundApiService.addComment(lostFoundId, commentController.text, parentId: replyingTo?.id);
                        }

                        if (success) {
                          // Tambahkan notifikasi lokal
                          await NotificationService.addNotification(
                            editingComment != null ? 'Komentar Diperbarui' : 'Komentar Berhasil', 
                            editingComment != null ? 'Anda telah memperbarui komentar.' : 'Anda telah mengomentari postingan.',
                            type: 'comment',
                            targetId: lostFoundId
                          );

                          commentController.clear();
                          setModalState(() {
                            isSending = false;
                            replyingTo = null;
                            editingComment = null;
                          });
                          // Refresh logic
                          setModalState(() {}); 
                          _fetchData(); 
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                        setModalState(() => isSending = false);
                      }
                    }
                  ),
                ],
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildEmptyComments() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("Belum ada komentar", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          const SizedBox(height: 8),
          Text("Jadilah yang pertama untuk berinteraksi!", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildThreadedComment(
    CommentModel comment, 
    StateSetter setModalState,
    Set<String> expandedIds,
    VoidCallback onRefresh,
    Function(CommentModel) onReply,
    Function(CommentModel) onEdit,
  ) {
    bool hasReplies = comment.replies.isNotEmpty;
    bool isExpanded = expandedIds.contains(comment.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCommentItem(comment, false, onRefresh, onReply, onEdit),
        if (hasReplies) ...[
          Padding(
            padding: const EdgeInsets.only(left: 58, bottom: 8),
            child: InkWell(
              onTap: () => setModalState(() {
                if (isExpanded) expandedIds.remove(comment.id);
                else expandedIds.add(comment.id);
              }),
              child: Row(
                children: [
                  Container(width: 40, height: 1, color: Colors.grey.shade300),
                  const SizedBox(width: 12),
                  Text(
                    isExpanded ? "Sembunyikan balasan" : "Lihat balasan (${comment.replies.length})",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Column(
                children: comment.replies.map((reply) => _buildCommentItem(reply, true, onRefresh, onReply, onEdit)).toList(),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildCommentItem(
    CommentModel comment, 
    bool isReply, 
    VoidCallback onRefresh,
    Function(CommentModel) onReply,
    Function(CommentModel) onEdit,
  ) {
    double horizontalPadding = 16.0;
    double avatarSize = isReply ? 12 : 16;
    
    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding, 
        right: horizontalPadding, 
        top: 6, 
        bottom: 6
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: avatarSize,
            backgroundColor: const Color(0xFF3D5AFE),
            backgroundImage: comment.userAvatar != null ? NetworkImage(comment.userAvatar!) : null,
            child: comment.userAvatar == null 
              ? Text((comment.userName ?? 'U')[0].toUpperCase(), style: TextStyle(color: Colors.white, fontSize: isReply ? 10 : 12))
              : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(comment.userName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 8),
                              Text(
                                _timeAgo(comment.createdAt), 
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.commentTextOnly, 
                            style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87)
                          ),
                        ],
                      ),
                    ),
                    _buildCommentMenu(comment, onEdit, onRefresh),
                  ],
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => onReply(comment),
                  child: Text("Balas", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(String dateTimeString) {
    if (dateTimeString.isEmpty) return 'Baru saja';
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      Duration diff = DateTime.now().difference(dateTime);
      if (diff.inDays >= 1) {
        return '${diff.inDays} hari lalu';
      } else if (diff.inHours >= 1) {
        return '${diff.inHours} jam lalu';
      } else if (diff.inMinutes >= 1) {
        return '${diff.inMinutes} mnt lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      // If it's already a relative string (like in dummy data)
      return dateTimeString;
    }
  }

  Widget _buildCommentMenu(CommentModel comment, Function(CommentModel) onEdit, VoidCallback onRefresh) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
      padding: EdgeInsets.zero,
      onSelected: (value) async {
        if (value == 'edit') {
          onEdit(comment);
        } else if (value == 'delete') {
          bool confirm = await _showConfirmDelete(context);
          if (confirm) {
            try {
              await LostFoundApiService.deleteComment(comment.id);
              onRefresh();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            }
          }
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
      ],
    );
  }

  Widget _buildCommentInput(
    TextEditingController controller, 
    bool isSending, 
    CommentModel? replyingTo,
    CommentModel? editingComment,
    VoidCallback onCancel,
    VoidCallback onSend,
  ) {
    bool isDirectAction = replyingTo != null || editingComment != null;
    String actionText = editingComment != null ? "Mengedit komentar..." : "Membalas ${replyingTo?.userName}...";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDirectAction)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(editingComment != null ? Icons.edit : Icons.reply, size: 14, color: const Color(0xFF3D5AFE)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(actionText, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF3D5AFE)))),
                    GestureDetector(onTap: onCancel, child: const Icon(Icons.cancel, size: 16, color: Colors.grey)),
                  ],
                ),
              ),
            Row(
              children: [
                Consumer<ProfilViewModel>(
                  builder: (context, profilVM, child) {
                    String? avatarUrl;
                    if (profilVM.userData != null) {
                      avatarUrl = profilVM.userData!['photo'] ?? profilVM.userData!['avatar'] ?? profilVM.userData!['profile_photo'];
                    }
                    
                    return CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: avatarUrl != null ? NetworkImage(LostFoundApiService.getFullUrl(avatarUrl)) : null,
                      child: avatarUrl == null ? const Icon(Icons.person, color: Colors.grey, size: 20) : null,
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            maxLines: null,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: "Tambahkan komentar...",
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {}, // Emoji picker could go here
                          child: const Icon(Icons.sentiment_satisfied_alt_outlined, color: Colors.black87, size: 22),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isSending)
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF3D5AFE), size: 24),
                    onPressed: onSend,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDelete(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Komentar?"),
        content: const Text("Apakah Anda yakin ingin menghapus komentar ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }
  void _showFinishConfirmation(BuildContext context, LostFoundModel item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Illustration Placeholder (based on design)
                const Icon(Icons.check_circle_outline, size: 100, color: Color(0xFF3D5AFE)),
                const SizedBox(height: 16),
                const Text(
                  "Tandai Postingan ini Selesai?",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Text(
                  "Ini tidak dapat dibatalkan dan postingan yang ditandai selesai tidak akan ditampilkan lagi di halaman utama karena kasusnya dianggap sudah selesai atau barang telah ditemukan.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 24),
                // Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context); // Close dialog
                      _deleteItem(item.lostfoundId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D5AFE),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Tandai Selesai", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text("Batalkan", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteItem(String lostFoundId) async {
    try {
      final success = await LostFoundApiService.deleteLostFound(lostFoundId);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Postingan berhasil diselesaikan dan dihapus')),
          );
          _fetchData(); // Refresh the list
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus postingan: $e')),
        );
      }
    }
  }
  void _showProfanityWarning(BuildContext context, List<String> detectedWords) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text("Peringatan Komentar", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Komentar Anda mengandung kata-kata yang tidak pantas:",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Text(
                detectedWords.join(", "),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Mohon gunakan bahasa yang lebih sopan agar tetap mematuhi standar komunitas kami.",
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("SAYA MENGERTI", style: TextStyle(color: Color(0xFF3D5AFE), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
