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
                  padding: const EdgeInsets.all(15),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _TaskMessageItem(
                      task: task,
                      isOwner: isOwner,
                      isMine: task.proposedBy == currentUser?.uid || task.userId == currentUser?.uid,
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
    bool isDeclined = task.status == 'declined';
    
    final timeFormat = DateFormat('HH:mm');
    final timeStr = "${task.startTime != null ? timeFormat.format(task.startTime!) : '--:--'} - ${task.endTime != null ? timeFormat.format(task.endTime!) : '--:--'}";
    
    double progress = task.assignees.isEmpty ? 0 : (task.completedBy.length / task.assignees.length);
    IconData taskIcon = task.iconCode != null ? IconData(task.iconCode!, fontFamily: 'MaterialIcons') : Icons.assignment_outlined;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFF2D3B55) : kCardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMine ? 20 : 0),
            bottomRight: Radius.circular(isMine ? 0 : 20),
          ),
          border: isPending ? Border.all(color: Colors.orangeAccent.withOpacity(0.5), width: 1) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Sender Name
            if (!isMine)
              FutureBuilder<Map<String, dynamic>?>(
                future: UserService().getUserData(task.proposedBy ?? task.userId),
                builder: (context, snapshot) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      snapshot.data?['name'] ?? "Thành viên",
                      style: const TextStyle(color: kPriority2Color, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            
            // Task Content
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: Icon(taskIcon, color: kPriority1Color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(timeStr, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                    ],
                  ),
                ),
                _StatusBadge(status: task.status),
              ],
            ),
            
            if (task.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  task.description,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.4),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Progress & Members
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Tiến độ", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
                          Text("${(progress * 100).toInt()}%", style: const TextStyle(color: kPriority1Color, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress, minHeight: 4,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: const AlwaysStoppedAnimation<Color>(kPriority1Color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                UserAvatarStack(uids: task.assignees, size: 24),
              ],
            ),

            const SizedBox(height: 12),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailPage(task: task))),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                  child: const Text("XEM CHI TIẾT", style: TextStyle(color: kPriority2Color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ],
            ),

            if (isPending && isOwner) ...[
              const Divider(color: Colors.white10, height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => GroupService().declineTask(task.id!),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), foregroundColor: Colors.redAccent, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text("Từ chối", style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => GroupService().approveTask(task.id!),
                      style: ElevatedButton.styleFrom(backgroundColor: kPriority1Color, foregroundColor: Colors.black, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text("Duyệt", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
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
