import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'group_model.dart';
import 'group_service.dart';
import 'task_model.dart';
import 'user_service.dart';
import 'main.dart'; 
import 'add_task_page.dart' hide kCardColor, kBackgroundColor, kPriority1Color, kPriority2Color;
import 'task_detail_page.dart' hide kCardColor, kBackgroundColor, kPriority1Color, kPriority2Color;

class GroupChatPage extends StatefulWidget {
  final Group group;
  const GroupChatPage({super.key, required this.group});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final GroupService _groupService = GroupService();
  final currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _memberEmailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Thêm thành viên", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Nhập email người bạn muốn mời vào nhóm.", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: _memberEmailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "example@email.com",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.black.withOpacity(0.2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () async {
              try {
                await _groupService.addMember(widget.group.id, _memberEmailController.text.trim());
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm thành viên!"), behavior: SnackBarBehavior.floating));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: kPriority1Color, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("Thêm", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) return;
    _messageController.clear();
    await _groupService.sendChatMessage(widget.group.id, currentUser!.uid, text);
  }

  @override
  Widget build(BuildContext context) {
    bool isOwner = currentUser?.uid == widget.group.ownerId;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBackgroundColor,
      endDrawer: _buildMemberDrawer(),
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: GestureDetector(
          onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.group.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("${widget.group.members.length} thành viên • Trực tuyến", style: TextStyle(fontSize: 11, color: kPriority1Color.withOpacity(0.8), fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.assignment_add, color: Colors.white70), onPressed: () => _navigateToAddTask(isOwner)),
          if (isOwner)
            IconButton(icon: const Icon(Icons.person_add_rounded, color: Colors.white70), onPressed: _showAddMemberDialog),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white.withOpacity(0.05), height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<dynamic>>(
              stream: _groupService.getGroupCombinedMessages(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kPriority1Color, strokeWidth: 2));
                }
                final items = snapshot.data ?? [];
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    if (item is Task) {
                      return _TaskMessageItem(
                        task: item,
                        isOwner: isOwner,
                        isMine: item.proposedBy == currentUser?.uid || (item.proposedBy == null && item.userId == currentUser?.uid),
                      );
                    } else {
                      final chat = item as Map<String, dynamic>;
                      return _ChatMessageItem(
                        chat: chat,
                        isMine: chat['senderId'] == currentUser?.uid,
                      );
                    }
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMemberDrawer() {
    return Drawer(
      backgroundColor: kCardColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            color: kBackgroundColor,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Thành viên nhóm", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text("${widget.group.members.length} thành viên", style: TextStyle(color: kPriority1Color.withOpacity(0.8), fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: widget.group.members.length,
              itemBuilder: (context, index) {
                final uid = widget.group.members[index];
                return FutureBuilder<Map<String, dynamic>?>(
                  future: UserService().getUserData(uid),
                  builder: (context, snapshot) {
                    final userData = snapshot.data;
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundImage: (userData?['photo'] != null) ? NetworkImage(userData!['photo']) : null,
                        child: userData?['photo'] == null ? const Icon(Icons.person, size: 20) : null,
                      ),
                      title: Text(userData?['name'] ?? "Đang tải...", style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                      subtitle: Text(uid == widget.group.ownerId ? "Chủ nhóm" : "Thành viên", style: TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: uid == currentUser?.uid ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: kPriority1Color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Text("BẠN", style: TextStyle(color: kPriority1Color, fontSize: 10, fontWeight: FontWeight.bold))) : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(color: kBackgroundColor, border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.05))),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Nhập tin nhắn...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              height: 48, width: 48,
              decoration: const BoxDecoration(color: kPriority1Color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: kPriority1Color, blurRadius: 8, offset: Offset(0, 3), spreadRadius: -2)]),
              child: const Icon(Icons.send_rounded, color: Colors.black, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddTask(bool isOwner) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddTaskPage(groupId: widget.group.id, initialStatus: isOwner ? 'approved' : 'pending')));
  }
}

class _ChatMessageItem extends StatelessWidget {
  final Map<String, dynamic> chat;
  final bool isMine;
  const _ChatMessageItem({required this.chat, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final timestamp = chat['timestamp'] as Timestamp?;
    final timeStr = timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : "";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: UserService().getUserData(chat['senderId']),
            builder: (context, snapshot) {
              final userData = snapshot.data;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMine) ...[_buildMiniAvatar(userData?['photo']), const SizedBox(width: 6)],
                    Text(isMine ? "Bạn" : (userData?['name'] ?? "..."), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text(timeStr, style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 9)),
                    if (isMine) ...[const SizedBox(width: 6), _buildMiniAvatar(userData?['photo'])],
                  ],
                ),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMine ? const Color(0xFF334155) : kCardColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMine ? 16 : 4), bottomRight: Radius.circular(isMine ? 4 : 16),
              ),
            ),
            child: Text(chat['text'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAvatar(String? url) => CircleAvatar(radius: 8, backgroundColor: Colors.white10, backgroundImage: url != null ? NetworkImage(url) : null, child: url == null ? const Icon(Icons.person, size: 8) : null);
}

class _TaskMessageItem extends StatelessWidget {
  final Task task;
  final bool isOwner;
  final bool isMine;
  const _TaskMessageItem({required this.task, required this.isOwner, required this.isMine});

  @override
  Widget build(BuildContext context) {
    bool isPending = task.status == 'pending';
    final now = DateTime.now();
    // Logic mới: Task hết hạn nếu chưa duyệt và đã quá endTime
    bool isExpired = isPending && task.endTime != null && now.isAfter(task.endTime!);
    
    final timeFormat = DateFormat('HH:mm');
    final creationTimeStr = timeFormat.format(task.createdAt);
    final taskTimeStr = "${task.startTime != null ? timeFormat.format(task.startTime!) : '--:--'} - ${task.endTime != null ? timeFormat.format(task.endTime!) : '--:--'}";
    double progress = task.assignees.isEmpty ? 0 : (task.completedBy.length / task.assignees.length);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: UserService().getUserData(task.proposedBy ?? task.userId),
            builder: (context, snapshot) {
              final userData = snapshot.data;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMine) ...[_buildMiniAvatar(userData?['photo']), const SizedBox(width: 6)],
                    Text(isMine ? "Bạn" : (userData?['name'] ?? "..."), style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    Text(creationTimeStr, style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10)),
                    if (isMine) ...[const SizedBox(width: 6), _buildMiniAvatar(userData?['photo'])],
                  ],
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailPage(task: task))),
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
              decoration: BoxDecoration(
                color: isMine ? const Color(0xFF1E293B) : kCardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMine ? 20 : 4), bottomRight: Radius.circular(isMine ? 4 : 20),
                ),
                border: Border.all(color: isExpired ? Colors.redAccent.withOpacity(0.3) : (isPending ? Colors.orangeAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05))),
              ),
              child: Opacity(
                opacity: isExpired ? 0.6 : 1.0,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kPriority1Color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(task.iconCode != null ? IconData(task.iconCode!, fontFamily: 'MaterialIcons') : Icons.assignment, color: kPriority1Color, size: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(taskTimeStr, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                          ])),
                          _StatusBadge(status: task.status, isExpired: isExpired),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.black12, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
                      child: Row(
                        children: [
                          Expanded(child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: Colors.white10, valueColor: const AlwaysStoppedAnimation(kPriority1Color))),
                          const SizedBox(width: 10),
                          Text("${(progress * 100).toInt()}%", style: const TextStyle(color: kPriority1Color, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          UserAvatarStack(uids: task.assignees, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isPending && isOwner && task.id != null && !isExpired)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  _ActionButton(label: "Từ chối", color: Colors.redAccent, onPressed: () => GroupService().declineTask(task.id!)),
                  const SizedBox(width: 8),
                  _ActionButton(label: "Phê duyệt", color: kPriority1Color, isPrimary: true, onPressed: () => GroupService().approveTask(task.id!)),
                ],
              ),
            ),
          if (isExpired)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
              child: Text("Hết hạn duyệt", style: TextStyle(color: Colors.redAccent.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniAvatar(String? url) => CircleAvatar(radius: 8, backgroundColor: Colors.white10, backgroundImage: url != null ? NetworkImage(url) : null, child: url == null ? const Icon(Icons.person, size: 8) : null);
}

class _ActionButton extends StatelessWidget {
  final String label; final Color color; final VoidCallback onPressed; final bool isPrimary;
  const _ActionButton({required this.label, required this.color, required this.onPressed, this.isPrimary = false});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: isPrimary ? color : Colors.transparent, borderRadius: BorderRadius.circular(8), border: isPrimary ? null : Border.all(color: color.withOpacity(0.5))),
        child: Text(label, style: TextStyle(color: isPrimary ? Colors.black : color, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isExpired;
  const _StatusBadge({required this.status, this.isExpired = false});
  @override
  Widget build(BuildContext context) {
    if (isExpired) {
      return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Text("HẾT HẠN", style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)));
    }
    Color c = (status == 'pending') ? Colors.orangeAccent : (status == 'declined' ? Colors.redAccent : kPriority1Color);
    String t = (status == 'pending') ? "CHỜ DUYỆT" : (status == 'declined' ? "TỪ CHỐI" : "ĐÃ DUYỆT");
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(t, style: TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.bold)));
  }
}
