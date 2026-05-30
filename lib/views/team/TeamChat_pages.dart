import 'package:flutter/material.dart';
import 'package:younifirst_app/models/chat_message_model.dart';
import 'package:younifirst_app/services/api/chat_service.dart';
import 'package:younifirst_app/services/input/auth_service.dart';
import 'package:younifirst_app/services/api/user_api_service.dart';
import 'package:younifirst_app/services/api/team_api_service.dart';

class TeamChatPage extends StatefulWidget {
  final String teamId;
  final String teamName;

  const TeamChatPage({
    Key? key,
    required this.teamId,
    required this.teamName,
  }) : super(key: key);

  @override
  State<TeamChatPage> createState() => _TeamChatPageState();
}

class _TeamChatPageState extends State<TeamChatPage> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  List<ChatMessageModel> _messages = [];
  bool _isSending = false;

  // Stream messages dari Firestore
  Stream<List<ChatMessageModel>>? _messagesStream;
  bool _isAuthenticating = true;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      // Pastikan kita mendapatkan token dari Laravel dan login ke Firebase Auth
      await AuthService.loginToFirebaseWithCustomToken();
      if (mounted) {
        setState(() {
          _messagesStream = ChatService.getMessagesStream(widget.teamId);
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _authError = e.toString();
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _msgController.clear();

    try {
      await ChatService.sendMessage(widget.teamId, text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showChatOptions(ChatMessageModel msg) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Color(0xFF3D5AFE)),
                title: const Text('Edit Pesan'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(msg);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Pesan', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(msg);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(ChatMessageModel msg) {
    final editController = TextEditingController(text: msg.message);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Edit Pesan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: TextField(
            controller: editController,
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Edit pesan...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D5AFE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final newText = editController.text.trim();
                if (newText.isEmpty) return;
                Navigator.pop(context);
                try {
                  await ChatService.editMessage(widget.teamId, msg.id, newText);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengedit pesan: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmDialog(ChatMessageModel msg) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Hapus Pesan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: const Text('Apakah Anda yakin ingin menghapus pesan ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ChatService.deleteMessage(widget.teamId, msg.id);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus pesan: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  String cacheBustedUrl(String url) {
    if (url.contains('?')) return '$url&v=${DateTime.now().millisecondsSinceEpoch}';
    return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Widget _buildAvatar(String userId, String userName, double radius) {
    String initial = userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : '?';
    Widget fallback = CircleAvatar(
      radius: radius,
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
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.75,
          ),
        ),
      ),
    );

    if (userId.isNotEmpty) {
      return FutureBuilder<Map<String, dynamic>?>(
        future: UserApiService.getUserByIdCached(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: Colors.transparent,
              child: SizedBox(width: radius, height: radius, child: const CircularProgressIndicator(strokeWidth: 2)),
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
              radius: radius,
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

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).textTheme.bodyLarge?.color, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE8EAFF),
            child: Text(
              widget.teamName.isNotEmpty ? widget.teamName[0].toUpperCase() : 'T',
              style: const TextStyle(
                color: Color(0xFF3D5AFE),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.teamName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const Text(
                  '4 aktif',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () {},
        )
      ],
    );
  }

  Widget _buildSystemWelcomeMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD0E0FF)),
      ),
      child: const Text(
        'Selamat datang di grup tim! 👋 Silakan mulai berdiskusi dan berkolaborasi dengan anggota tim lainnya. Mohon untuk selalu menjaga sopan santun dan menggunakan bahasa yang baik selama berkomunikasi.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF3D5AFE),
          fontSize: 12,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isAuthenticating) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF3D5AFE)),
            SizedBox(height: 16),
            Text('Menghubungkan ke server chat...'),
          ],
        ),
      );
    }

    if (_authError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 16),
              Text('Gagal terhubung:\n$_authError', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<ChatMessageModel>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _messages.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3D5AFE)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 50, color: Colors.grey),
                const SizedBox(height: 12),
                Text('Terjadi kesalahan: ${snapshot.error}', textAlign: TextAlign.center,),
              ],
            ),
          );
        }

        if (snapshot.hasData) {
          _messages = snapshot.data!;
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }

        if (_messages.isEmpty) {
          return Column(
            children: [
              _buildSystemWelcomeMessage(),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8EAFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_outline,
                            size: 40, color: Color(0xFF3D5AFE)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Belum ada pesan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Mulai diskusi dengan anggota tim!',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
          itemCount: _messages.length + 1,
          itemBuilder: (ctx, i) {
            if (i == 0) {
              return _buildSystemWelcomeMessage();
            }
            final msg = _messages[i - 1];
            final isMe = msg.senderId == AuthService.loggedInUserId;
            final showName = !isMe &&
                (i - 1 == 0 || _messages[i - 2].senderId != msg.senderId);
            return _buildBubble(msg, isMe, showName);
          },
        );
      },
    );
  }

  Widget _buildBubble(ChatMessageModel msg, bool isMe, bool showName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(msg.senderId, msg.senderName, 16),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: isMe ? () => _showChatOptions(msg) : null,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF3D5AFE) : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isMe) ...[
                          Text(
                            msg.senderName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D5AFE),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          msg.message,
                          style: TextStyle(
                            color: isMe ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (msg.isEdited) ...[
                                Text(
                                  '(edited) ',
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white.withOpacity(0.6)
                                        : Colors.grey.shade500,
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                              Text(
                                msg.timeLabel,
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white.withOpacity(0.7)
                                      : Colors.grey.shade500,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(msg.senderId, msg.senderName, 16),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.sentiment_satisfied_alt_outlined, color: Colors.grey),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Ketik Pesan...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isSending
                    ? Colors.grey.shade400
                    : const Color(0xFF3D5AFE),
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
