import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'group_model.dart';
import 'group_service.dart';
import 'task_model.dart';
import 'task_service.dart';
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
            Text(
              "Nhập email người bạn muốn mời vào nhóm.",
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _memberEmailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "example@email.com",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.black.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Hủy", style: TextStyle(color: Colors.white54))
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _groupService.addMember(widget.group.id, _memberEmailController.text.trim());
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Đã thêm thành viên!"),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  )
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()), 
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  )
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPriority1Color,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text("Thêm", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isOwner = currentUser?.uid == widget.group.ownerId;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.group.name, 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
            ),
            Text(
              "${widget.group.members.length} thành viên • Trực tuyến", 
              style: TextStyle(fontSize: 11, color: kPriority1Color.withOpacity(0.8), fontWeight: FontWeight.w500)
            ),
          ],
        ),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.person_add_rounded, color: Colors.white70), 
              onPressed: _showAddMemberDialog
            ),
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
            child: StreamBuilder<List<Task>>(
              stream: _groupService.getGroupTasks(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kPriority1Color, strokeWidth: 2));
                }
                final tasks = snapshot.data ?? [];
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: kCardColor.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.forum_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Chưa có tin nhắn nhiệm vụ nào", 
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15, fontWeight: FontWeight.w500)
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Hãy bắt đầu bằng cách tạo một nhiệm vụ mới", 
                          style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 13)
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _TaskMessageItem(
                      task: task,
                      isOwner: isOwner,
                      isMine: task.proposedBy == currentUser?.uid || (task.proposedBy == null && task.userId == currentUser?.uid),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(isOwner),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isOwner) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToAddTask(isOwner),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: kCardColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.assignment_add, size: 20, color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 12),
                    Text(
                      isOwner ? "Tạo nhiệm vụ cho nhóm..." : "Đề xuất nhiệm vụ...",
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _navigateToAddTask(isOwner),
            child: Container(
              height: 48, width: 48,
              decoration: const BoxDecoration(
                color: kPriority1Color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: kPriority1Color, blurRadius: 10, offset: Offset(0, 4), spreadRadius: -2)
                ],
              ),
              child: const Icon(Icons.add_task_rounded, color: Colors.black, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddTask(bool isOwner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTaskPage(
          groupId: widget.group.id,
          initialStatus: isOwner ? 'approved' : 'pending',
        ),
      ),
    );
  }
}

class _TaskMessageItem extends StatelessWidget {
  final Task task;
  final bool isOwner;
  final bool isMine;

  const _TaskMessageItem({
    required this.task,
    required this.isOwner,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    bool isPending = task.status == 'pending';
    
    final timeFormat = DateFormat('HH:mm');
    final creationTimeStr = timeFormat.format(task.createdAt);
    final taskTimeStr = "${task.startTime != null ? timeFormat.format(task.startTime!) : '--:--'} - ${task.endTime != null ? timeFormat.format(task.endTime!) : '--:--'}";
    
    double progress = task.assignees.isEmpty ? 0 : (task.completedBy.length / task.assignees.length);
    IconData taskIcon = task.iconCode != null ? IconData(task.iconCode!, fontFamily: 'MaterialIcons') : Icons.assignment_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, and Creation Time
          FutureBuilder<Map<String, dynamic>?>(
            future: UserService().getUserData(task.proposedBy ?? task.userId),
            builder: (context, snapshot) {
              final userData = snapshot.data;
              final name = userData?['name'] ?? "Thành viên";
              final photoUrl = userData?['photo'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMine) ...[
                      _buildAvatar(photoUrl),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      isMine ? "Bạn" : name,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      creationTimeStr,
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 8),
                      _buildAvatar(photoUrl),
                    ],
                  ],
                ),
              );
            },
          ),

          // Task Card
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
              decoration: BoxDecoration(
                color: isMine ? const Color(0xFF2D3B55) : kCardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMine ? 20 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 20),
                ),
                border: Border.all(
                  color: isPending 
                      ? Colors.orangeAccent.withOpacity(0.3) 
                      : Colors.white.withOpacity(0.05), 
                  width: 1
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upper Section: Icon, Title, Status
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kPriority1Color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(taskIcon, color: kPriority1Color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.schedule_rounded, size: 12, color: Colors.white.withOpacity(0.4)),
                                      const SizedBox(width: 4),
                                      Text(
                                        taskTimeStr,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(status: task.status),
                          ],
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            task.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Lower Section: Progress and Assignees
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Tiến độ",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "${(progress * 100).toInt()}%",
                                    style: const TextStyle(
                                      color: kPriority1Color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 4,
                                  backgroundColor: Colors.white.withOpacity(0.05),
                                  valueColor: const AlwaysStoppedAnimation<Color>(kPriority1Color),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        UserAvatarStack(uids: task.assignees, size: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Owner Actions for Pending Tasks
          if (isPending && isOwner)
            Padding(
              padding: const EdgeInsets.only(top: 10, right: 4, left: 4),
              child: Row(
                mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  _ActionButton(
                    label: "Từ chối",
                    color: Colors.redAccent,
                    onPressed: () => GroupService().declineTask(task.id!),
                  ),
                  const SizedBox(width: 10),
                  _ActionButton(
                    label: "Phê duyệt",
                    color: kPriority1Color,
                    isPrimary: true,
                    onPressed: () => GroupService().approveTask(task.id!),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(dynamic photoUrl) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: kPriority1Color.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        radius: 10,
        backgroundColor: kCardColor,
        backgroundImage: (photoUrl != null && photoUrl.toString().startsWith('http')) ? NetworkImage(photoUrl) : null,
        child: (photoUrl == null || !photoUrl.toString().startsWith('http')) 
            ? const Icon(Icons.person, size: 10, color: Colors.white54) 
            : null,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isPrimary ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isPrimary ? null : Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.black : color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (status) {
      case 'pending':
        color = Colors.orangeAccent; text = "CHỜ DUYỆT"; break;
      case 'declined':
        color = Colors.redAccent; text = "TỪ CHỐI"; break;
      default:
        color = kPriority1Color; text = "ĐÃ DUYỆT";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(6), 
        border: Border.all(color: color.withOpacity(0.2))
      ),
      child: Text(
        text, 
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)
      ),
    );
  }
}
