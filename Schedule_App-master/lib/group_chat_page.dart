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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Thêm thành viên", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _memberEmailController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Email thành viên",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: kPriority1Color)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              try {
                await _groupService.addMember(widget.group.id, _memberEmailController.text.trim());
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm thành viên!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
              }
            },
            child: const Text("Thêm", style: TextStyle(color: kPriority1Color, fontWeight: FontWeight.bold)),
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
        backgroundColor: kCardColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.group.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("${widget.group.members.length} thành viên", style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
          ],
        ),
        actions: [
          if (isOwner)
            IconButton(icon: const Icon(Icons.person_add_alt_1_outlined), onPressed: _showAddMemberDialog),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _groupService.getGroupTasks(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kPriority1Color));
                }
                final tasks = snapshot.data ?? [];
                if (tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined, size: 60, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 10),
                        Text("Chưa có task nào trong nhóm này", style: TextStyle(color: Colors.white.withOpacity(0.3))),
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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isOwner ? "Tạo nhiệm vụ cho nhóm..." : "Đề xuất nhiệm vụ cho nhóm...",
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTaskPage(
                    groupId: widget.group.id,
                    initialStatus: isOwner ? 'approved' : 'pending',
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: kPriority1Color, shape: BoxShape.circle),
              child: const Icon(Icons.add_task, color: Colors.black),
            ),
          ),
        ],
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
      margin: const EdgeInsets.only(bottom: 24),
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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMine) ...[
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white10,
                        backgroundImage: (photoUrl != null && photoUrl.toString().startsWith('http')) ? NetworkImage(photoUrl) : null,
                        child: (photoUrl == null || !photoUrl.toString().startsWith('http')) ? const Icon(Icons.person, size: 12, color: Colors.white54) : null,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      isMine ? "Bạn" : name,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      " • $creationTimeStr",
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white10,
                        backgroundImage: (photoUrl != null && photoUrl.toString().startsWith('http')) ? NetworkImage(photoUrl) : null,
                        child: (photoUrl == null || !photoUrl.toString().startsWith('http')) ? const Icon(Icons.person, size: 12, color: Colors.white54) : null,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          // Task Card
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9),
            decoration: BoxDecoration(
              color: isMine ? const Color(0xFF2D3B55) : kCardColor,
              borderRadius: BorderRadius.circular(24),
              border: isPending 
                  ? Border.all(color: Colors.orangeAccent.withOpacity(0.4), width: 1.5) 
                  : Border.all(color: Colors.white.withOpacity(0.05), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upper Section: Icon, Title, Status
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: kPriority1Color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(taskIcon, color: kPriority1Color, size: 22),
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
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 12, color: Colors.white.withOpacity(0.4)),
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
                          _StatusBadge(status: task.status),
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          task.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
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
                              borderRadius: BorderRadius.circular(4),
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
                      const SizedBox(width: 16),
                      UserAvatarStack(uids: task.assignees, size: 28),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
                        ),
                        icon: const Icon(Icons.arrow_forward_ios, size: 14, color: kPriority2Color),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Owner Actions for Pending Tasks
          if (isPending && isOwner)
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 4, left: 4),
              child: Row(
                mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  _ActionButton(
                    label: "Từ chối",
                    color: Colors.redAccent,
                    onPressed: () => GroupService().declineTask(task.id!),
                  ),
                  const SizedBox(width: 12),
                  _ActionButton(
                    label: "Duyệt ngay",
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
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: color.withOpacity(0.3)),
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
        color = Colors.orangeAccent; text = "PENDING"; break;
      case 'declined':
        color = Colors.redAccent; text = "DECLINED"; break;
      default:
        color = kPriority1Color; text = "APPROVED";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(text, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}
