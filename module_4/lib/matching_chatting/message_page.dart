import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../components/bottom_nav_bar.dart';
import '../components/main_shell.dart';
import '../services/firestore_service.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../authentication_profile/auth_tabs_page.dart';
import '../models/user_profile.dart';
import '../models/job.dart';

class MessagePage extends StatefulWidget {
  final String? chatId;
  final bool showBottomNav;
  
  const MessagePage({super.key, this.chatId, this.showBottomNav = true});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage>
    with SingleTickerProviderStateMixin {
  int _selectedNavIndex = 2;
  final FirestoreService _service = FirestoreService();
  final TextEditingController _inputCtrl = TextEditingController();
  final Map<String, UserProfile?> _userCache = {};
  final ScrollController _scrollController = ScrollController();

  late AnimationController _headerController;
  late Animation<double> _headerAnimation;

  Future<UserProfile?> _getUser(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid];
    final u = await _service.getUserProfile(uid);
    _userCache[uid] = u;
    return u;
  }

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _inputCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A1628),
          elevation: 0,
          title: const Text('Login', style: TextStyle(color: Colors.white)),
        ),
        body: const AuthTabsPage(),
        bottomNavigationBar: widget.showBottomNav
            ? CustomBottomNavBar(
                selectedIndex: _selectedNavIndex,
                onTap: (index) {
                  setState(() => _selectedNavIndex = index);
                  _navigateToPage(index);
                },
              )
            : null,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: widget.chatId == null
          ? _buildChatListView()
          : _buildChatRoomView(widget.chatId!),
      bottomNavigationBar: (widget.chatId == null && widget.showBottomNav)
          ? CustomBottomNavBar(
              selectedIndex: _selectedNavIndex,
              onTap: (index) {
                setState(() => _selectedNavIndex = index);
                _navigateToPage(index);
              },
            )
          : null,
    );
  }

  // ============================================================================
  // CHAT LIST VIEW
  // ============================================================================

  Widget _buildChatListView() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        _buildChatListContent(),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0A1628),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1628), Color(0xFF1A3A5C), Color(0xFF0F2847)],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _headerAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Messages',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Chat with employers & applicants',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
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
    );
  }

  Widget _buildChatListContent() {
    return StreamBuilder<List<Chat>>(
      stream: _service.streamMyChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            ),
          );
        }

        final chats = snapshot.data ?? [];
        if (chats.isEmpty) {
          return SliverFillRemaining(child: _buildEmptyState());
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final chat = chats[index];
                return _ChatListItem(
                  chat: chat,
                  service: _service,
                  getUser: _getUser,
                  animationDelay: index * 80,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MessagePage(chatId: chat.id),
                      ),
                    );
                  },
                );
              },
              childCount: chats.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start chatting by applying to jobs\nor connecting with applicants',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // CHAT ROOM VIEW
  // ============================================================================

  Widget _buildChatRoomView(String chatId) {
    return Column(
      children: [
        _buildChatRoomHeader(chatId),
        Expanded(child: _buildMessagesList(chatId)),
        _buildMessageInput(chatId),
      ],
    );
  }

  Widget _buildChatRoomHeader(String chatId) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF1A3A5C)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1628).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: StreamBuilder<Chat?>(
          stream: _service.streamChat(chatId),
          builder: (context, chatSnap) {
            final chat = chatSnap.data;
            final otherUid = chat?.participants.firstWhere(
                  (p) => p != _service.uid,
                  orElse: () => _service.uid,
                ) ??
                '';

            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                    ),
                  ),
                  FutureBuilder<UserProfile?>(
                    future: _getUser(otherUid),
                    builder: (context, userSnap) {
                      final user = userSnap.data;
                      final hasPhoto = (user?.photoUrl ?? '').isNotEmpty;
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: hasPhoto
                            ? CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(user!.photoUrl),
                              )
                            : CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF3B82F6),
                                child: Text(
                                  (user?.displayName.isNotEmpty == true
                                          ? user!.displayName[0]
                                          : '?')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FutureBuilder<UserProfile?>(
                          future: _getUser(otherUid),
                          builder: (context, snap) {
                            final name = snap.data?.displayName ?? 'User';
                            return Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                        const SizedBox(height: 2),
                        FutureBuilder<Job?>(
                          future: chat != null
                              ? _service.getJob(chat.jobId)
                              : Future.value(null),
                          builder: (context, jobSnap) {
                            final jobTitle = jobSnap.data?.title ?? '';
                            return Text(
                              jobTitle.isEmpty ? 'Conversation' : jobTitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessagesList(String chatId) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: StreamBuilder<List<Message>>(
        stream: _service.streamMessages(chatId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
            );
          }

          final msgs = snapshot.data ?? [];
          if (msgs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.waving_hand_rounded,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Say hello!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: msgs.length,
            itemBuilder: (context, index) {
              final m = msgs[index];
              final mine = m.senderId == _service.uid;
              final showDate = index == 0 ||
                  !_isSameDay(msgs[index - 1].sentAt, m.sentAt);

              return Column(
                children: [
                  if (showDate) _buildDateDivider(m.sentAt),
                  _MessageBubble(
                    message: m,
                    isMine: mine,
                    getUser: _getUser,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    final isToday = _isSameDay(date, now);
    final isYesterday = _isSameDay(date, now.subtract(const Duration(days: 1)));

    String text;
    if (isToday) {
      text = 'Today';
    } else if (isYesterday) {
      text = 'Yesterday';
    } else {
      text = '${date.day}/${date.month}/${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildMessageInput(String chatId) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(chatId),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => _sendMessage(chatId),
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendMessage(String chatId) async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    await _service.sendMessage(chatId, text);
    _inputCtrl.clear();
  }

  void _navigateToPage(int index) {
    // If we're inside MainShell, use smooth navigation
    final shellState = MainShellState.shellKey.currentState;
    if (shellState != null && !widget.showBottomNav) {
      shellState.navigateToTab(index);
      return;
    }
    
    // Fallback to traditional navigation
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/discovery');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/my_jobs');
        break;
      case 2:
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }
}

// ============================================================================
// CHAT LIST ITEM WIDGET
// ============================================================================

class _ChatListItem extends StatefulWidget {
  final Chat chat;
  final FirestoreService service;
  final Future<UserProfile?> Function(String) getUser;
  final int animationDelay;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.chat,
    required this.service,
    required this.getUser,
    required this.animationDelay,
    required this.onTap,
  });

  @override
  State<_ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<_ChatListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherUid = widget.chat.participants.firstWhere(
      (p) => p != widget.service.uid,
      orElse: () => widget.service.uid,
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A1628).withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Avatar
                    FutureBuilder<UserProfile?>(
                      future: widget.getUser(otherUid),
                      builder: (context, userSnap) {
                        final user = userSnap.data;
                        final hasPhoto = (user?.photoUrl ?? '').isNotEmpty;
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: hasPhoto
                              ? CircleAvatar(
                                  radius: 26,
                                  backgroundImage:
                                      NetworkImage(user!.photoUrl),
                                )
                              : CircleAvatar(
                                  radius: 26,
                                  backgroundColor: const Color(0xFF3B82F6),
                                  child: Text(
                                    (user?.displayName.isNotEmpty == true
                                            ? user!.displayName[0]
                                            : '?')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                        );
                      },
                    ),
                    const SizedBox(width: 14),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Job title and time
                          Row(
                            children: [
                              Expanded(
                                child: FutureBuilder<Job?>(
                                  future:
                                      widget.service.getJob(widget.chat.jobId),
                                  builder: (context, jobSnap) {
                                    final title =
                                        jobSnap.data?.title ?? 'Chat';
                                    return Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ),
                              StreamBuilder<Message?>(
                                stream: widget.service
                                    .streamLastMessage(widget.chat.id),
                                builder: (context, msgSnap) {
                                  final when = msgSnap.data?.sentAt;
                                  if (when == null) return const SizedBox();
                                  final timeText =
                                      '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
                                  return Text(
                                    timeText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // User name
                          FutureBuilder<UserProfile?>(
                            future: widget.getUser(otherUid),
                            builder: (context, snap) {
                              final name = snap.data?.displayName ?? '';
                              return Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                          const SizedBox(height: 4),

                          // Last message preview
                          StreamBuilder<Message?>(
                            stream: widget.service
                                .streamLastMessage(widget.chat.id),
                            builder: (context, msgSnap) {
                              final preview =
                                  msgSnap.data?.text ?? 'No messages yet';
                              return Text(
                                preview,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MESSAGE BUBBLE WIDGET
// ============================================================================

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final Future<UserProfile?> Function(String) getUser;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.getUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) _buildAvatar(message.senderId),
          if (!isMine) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMine
                    ? const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      )
                    : null,
                color: isMine ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMine
                        ? const Color(0xFF3B82F6).withOpacity(0.3)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMine ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.sentAt.hour.toString().padLeft(2, '0')}:${message.sentAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMine) const SizedBox(width: 8),
          if (isMine) _buildAvatar(message.senderId),
        ],
      ),
    );
  }

  Widget _buildAvatar(String uid) {
    return FutureBuilder<UserProfile?>(
      future: getUser(uid),
      builder: (context, snap) {
        final user = snap.data;
        final hasPhoto = (user?.photoUrl ?? '').isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: hasPhoto
              ? CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(user!.photoUrl),
                )
              : CircleAvatar(
                  radius: 14,
                  backgroundColor:
                      isMine ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                  child: Text(
                    (user?.displayName.isNotEmpty == true
                            ? user!.displayName[0]
                            : '?')
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isMine ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
