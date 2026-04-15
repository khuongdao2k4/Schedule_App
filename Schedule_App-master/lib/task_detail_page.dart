import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'task_model.dart';
import 'task_service.dart';
import 'user_service.dart';
import 'task_icons.dart';
import 'user_profile_page.dart';

const kBackgroundColor = Color(0xFF1B2333);
const kCardColor = Color(0xFF263042);
const kAccentColor = Color(0xFFC9E8A2);
const kPriority2Color = Color(0xFF4ED9F5);
const kPriority3Color = Color(0xFFCDC1D8);
const kTextSoft = Color(0xFF94A3B8);

class TaskDetailPage extends StatelessWidget {
  final Task task;
  const TaskDetailPage({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    bool isExpired = !task.isDone && task.endTime != null && now.isAfter(task.endTime!);
    bool isStarted = task.startTime == null || now.isAfter(task.startTime!);
    String status = task.isDone ? "Hoàn thành" : (isExpired ? "Hết hạn" : (isStarted ? "Đang chạy" : "Chưa tới giờ"));
    
    Color statusColor = task.isDone ? kAccentColor : (isExpired ? Colors.redAccent : (isStarted ? kPriority2Color : kTextSoft));
    final IconData displayIcon = task.iconCode != null ? IconData(task.iconCode!, fontFamily: 'MaterialIcons') : TaskIcons.getIconByTitle(task.title);

    int totalAssignees = task.assignees.length;
    int completedCount = task.completedBy.length;
    double progress = totalAssignees == 0 ? (task.isDone ? 1.0 : 0.0) : (completedCount / totalAssignees);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Chi tiết nhiệm vụ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(displayIcon, color: statusColor, size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(task.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                if (task.groupId != null) ...[
                                  const SizedBox(width: 8),
                                  _GroupBadgeDetail(groupId: task.groupId!),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoColumn(Icons.calendar_today_outlined, "Ngày", 
                        task.dueDate != null ? DateFormat('dd/MM/yyyy').format(task.dueDate!) : "N/A"),
                      _buildInfoColumn(Icons.access_time, "Thời gian", 
                        "${task.startTime != null ? DateFormat('HH:mm').format(task.startTime!) : '--:--'} - ${task.endTime != null ? DateFormat('HH:mm').format(task.endTime!) : '--:--'}"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Tiến độ
            const Text("Tiến độ", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Thành viên hoàn thành", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                      Text("$completedCount/$totalAssignees", style: const TextStyle(color: kAccentColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress, minHeight: 10,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: const AlwaysStoppedAnimation<Color>(kAccentColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text("${(progress * 100).toInt()}%", style: const TextStyle(color: kTextSoft, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Mô tả
            const Text("Mô tả", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kCardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Text(
                task.description.isEmpty ? "Không có mô tả chi tiết." : task.description,
                style: const TextStyle(color: kTextSoft, fontSize: 15, height: 1.5),
              ),
            ),
            const SizedBox(height: 30),

            // Chi tiết khác
            Row(
              children: [
                Expanded(child: _buildDetailTile("Ưu tiên", task.priority, Icons.flag_outlined, kPriority3Color)),
                const SizedBox(width: 16),
                Expanded(child: _buildDetailTile("Chủ đề", task.category, Icons.category_outlined, kPriority2Color)),
              ],
            ),
            const SizedBox(height: 30),

            // Assignees List
            const Text("Người tham gia", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (task.assignees.isEmpty)
              const Text("Chưa có người tham gia", style: TextStyle(color: kTextSoft))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: task.assignees.length,
                itemBuilder: (context, index) {
                  return _buildUserTile(context, task.assignees[index], task.completedBy.contains(task.assignees[index]));
                },
              ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: kTextSoft, size: 20),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: kTextSoft, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDetailTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: kTextSoft, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, String uid, bool isCompleted) {
    bool isOwner = uid == task.userId; // Xác định chủ sở hữu task

    return FutureBuilder<Map<String, dynamic>?>(
      future: UserService().getUserData(uid),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final name = userData?['name'] ?? "Đang tải...";
        final photoUrl = userData?['photo'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[800],
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null ? const Icon(Icons.person, color: Colors.white54) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      isOwner ? "Người tạo nhiệm vụ" : "Người tham gia",
                      style: TextStyle(color: isOwner ? kAccentColor : kTextSoft, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(color: kAccentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: kAccentColor, size: 14),
                      SizedBox(width: 4),
                      Text("Hoàn thành", style: TextStyle(color: kAccentColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                color: const Color(0xFF2E3A4F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                onSelected: (val) {
                  if (val == 'view_profile') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfilePage(uid: uid)));
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view_profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, color: Colors.white, size: 18),
                        SizedBox(width: 10),
                        Text("Xem trang cá nhân", style: TextStyle(color: Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GroupBadgeDetail extends StatelessWidget {
  final String groupId;
  const _GroupBadgeDetail({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('groups').doc(groupId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final groupName = snapshot.data?['name'] ?? 'Nhóm';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.groups_rounded, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  groupName,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
