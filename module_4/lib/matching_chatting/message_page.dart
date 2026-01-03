import 'package:flutter/material.dart';
import '../components/bottom_nav_bar.dart';
import '../services/firestore_service.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../authentication_profile/auth_tabs_page.dart';
import '../models/user_profile.dart';
import '../models/job.dart';

class MessagePage extends StatefulWidget {
  final String? chatId;
  const MessagePage({super.key, this.chatId});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  int _selectedNavIndex = 2; // Message tab
  final FirestoreService _service = FirestoreService();
  final TextEditingController _inputCtrl = TextEditingController();
  final Map<String, UserProfile?> _userCache = {};

  Future<UserProfile?> _getUser(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid];
    final u = await _service.getUserProfile(uid);
    _userCache[uid] = u;
    return u;
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 250, 250, 251),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F1E3C),
          elevation: 0,
          title: const Text(
            'Account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const AuthTabsPage(),
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedNavIndex,
          onTap: (index) {
            setState(() {
              _selectedNavIndex = index;
            });
            _navigateToPage(index);
          },
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 250, 251),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1E3C),
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: widget.chatId == null ? _buildChatList() : _buildChatRoom(widget.chatId!),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
          _navigateToPage(index);
        },
      ),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<List<Chat>>(
      stream: _service.streamMyChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final chats = snapshot.data ?? [];
        if (chats.isEmpty) {
          return Center(
            child: Text('No chats yet', style: TextStyle(color: Colors.grey[600])),
          );
        }
        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final otherUid = chat.participants.firstWhere(
              (p) => p != _service.uid,
              orElse: () => _service.uid,
            );
            return FutureBuilder<Job?>(
              future: _service.getJob(chat.jobId),
              builder: (context, jobSnap) {
                final jobTitle = jobSnap.data?.title ?? 'Chat';
                return StreamBuilder<Message?>(
                  stream: _service.streamLastMessage(chat.id),
                  builder: (context, msgSnap) {
                    final last = msgSnap.data;
                    final preview = last?.text ?? 'No messages';
                    final when = last?.sentAt;
                    final timeText = when == null
                        ? ''
                        : '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
                    return FutureBuilder<UserProfile?>(
                      future: _getUser(otherUid),
                      builder: (context, userSnap) {
                        final user = userSnap.data;
                        final hasPhoto = (user?.photoUrl ?? '').isNotEmpty;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: hasPhoto
                                ? CircleAvatar(backgroundImage: NetworkImage(user!.photoUrl))
                                : CircleAvatar(
                                    backgroundColor: const Color(0xFF0F1E3C),
                                    child: Text(
                                      (user?.displayName.isNotEmpty == true
                                              ? user!.displayName[0]
                                              : jobTitle.isNotEmpty
                                                  ? jobTitle[0]
                                                  : '?')
                                          .toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                            title: Text(jobTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: Text(timeText, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => MessagePage(chatId: chat.id)),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildChatRoom(String chatId) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Message>>(
            stream: _service.streamMessages(chatId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final msgs = snapshot.data ?? [];
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                itemCount: msgs.length,
                itemBuilder: (context, index) {
                  final m = msgs[index];
                  final mine = m.senderId == _service.uid;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment:
                          mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              mine ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            if (!mine)
                              FutureBuilder<UserProfile?>(
                                future: _getUser(m.senderId),
                                builder: (context, snap) {
                                  final u = snap.data;
                                  final hasPhoto = (u?.photoUrl ?? '').isNotEmpty;
                                  return hasPhoto
                                      ? CircleAvatar(radius: 14, backgroundImage: NetworkImage(u!.photoUrl))
                                      : const CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Color(0xFFE0E0E0),
                                          child: Icon(Icons.person, size: 16, color: Colors.black54),
                                        );
                                },
                              ),
                            if (!mine) const SizedBox(width: 6),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                constraints: const BoxConstraints(maxWidth: 300),
                                decoration: BoxDecoration(
                                  color: mine ? const Color(0xFF4CAF50) : const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  m.text,
                                  style: TextStyle(
                                    color: mine ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            if (mine) const SizedBox(width: 6),
                            if (mine)
                              FutureBuilder<UserProfile?>(
                                future: _getUser(_service.uid),
                                builder: (context, snap) {
                                  final u = snap.data;
                                  final hasPhoto = (u?.photoUrl ?? '').isNotEmpty;
                                  return hasPhoto
                                      ? CircleAvatar(radius: 14, backgroundImage: NetworkImage(u!.photoUrl))
                                      : const CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Color(0xFF4CAF50),
                                          child: Icon(Icons.person, size: 16, color: Colors.white),
                                        );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${m.sentAt.hour.toString().padLeft(2, '0')}:${m.sentAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          child: Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.chat_bubble_outline),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final t = _inputCtrl.text.trim();
                    if (t.isEmpty) return;
                    await _service.sendMessage(chatId, t);
                    _inputCtrl.clear();
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToPage(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/discovery');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/my_jobs');
        break;
      case 2:
        // Already on Message
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/profile');
        break;
    }
  }
}
