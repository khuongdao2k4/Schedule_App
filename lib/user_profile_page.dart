import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task_service.dart';
import 'task_model.dart';
import 'user_service.dart';
import 'main.dart';

class UserProfilePage extends StatelessWidget {
  final String uid;
  const UserProfilePage({super.key, required this.uid});

  String _getDefaultRank(List<Task> tasks) {
    final completedCount = tasks.where((t) => t.isDone).length;
    if (completedCount >= 100) return "Huyền thoại năng suất";
    if (completedCount >= 50) return "Bậc thầy điều phối";
    if (completedCount >= 20) return "Chuyên gia lập kế hoạch";
    if (completedCount >= 5) return "Chiến binh kỷ luật";
    return "Tân thủ tiềm năng";
  }

  @override
  Widget build(BuildContext context) {
    final TaskService taskService = TaskService();
    final UserService userService = UserService();
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Hồ sơ thành viên", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Task>>(
        stream: taskService.getTasks(uid),
        builder: (context, taskSnapshot) {
          final tasks = taskSnapshot.data ?? [];
          final doneTasks = tasks.where((t) => t.isDone).toList();
          
          return FutureBuilder<Map<String, dynamic>?>(
            future: userService.getUserData(uid),
            builder: (context, userSnapshot) {
              final userData = userSnapshot.data;
              final selectedBadge = userData?['selectedBadge'];
              final name = userData?['name'] ?? "Đang tải...";
              final photoUrl = userData?['photo'];
              final bool hideBadges = userData?['hideBadges'] ?? false;
              
              final bool isSelf = currentUser?.uid == uid;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildHeader(context, name, photoUrl, selectedBadge, tasks),
                    const SizedBox(height: 30),
                    _buildStatsRow(context, tasks.length, doneTasks.length),
                    const SizedBox(height: 35),
                    
                    if (isSelf || !hideBadges)
                      _buildBadgesSection(context, tasks)
                    else
                      _buildHiddenBadgesPlaceholder(),
                      
                    const SizedBox(height: 40),
                    const Text(
                      "Thông tin thành viên trong nhóm",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            }
          );
        }
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name, String? photoUrl, String? selectedBadge, List<Task> tasks) {
    Color badgeColor = kPriority1Color;
    String displayRank = selectedBadge ?? _getDefaultRank(tasks);
    
    if (displayRank.contains("Huyền thoại")) badgeColor = Colors.amber;
    else if (displayRank.contains("Khủng hoảng")) badgeColor = Colors.redAccent;
    else if (displayRank.contains("Học giả")) badgeColor = Colors.indigoAccent;
    else if (displayRank.contains("Công việc")) badgeColor = Colors.orangeAccent;
    else if (displayRank.contains("Thép")) badgeColor = Colors.greenAccent;
    else if (displayRank.contains("Điều phối")) badgeColor = Colors.purpleAccent;
    else if (displayRank.contains("Chuyên gia")) badgeColor = Colors.teal;
    else if (displayRank.contains("Chiến binh")) badgeColor = Colors.green;
    else badgeColor = Colors.blueGrey;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: kPriority1Color, width: 2.5),
          ),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: kCardColor,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null ? const Icon(Icons.person, size: 50, color: Colors.white24) : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badgeColor.withOpacity(0.4), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_rounded, size: 14, color: badgeColor),
              const SizedBox(width: 6),
              Text(
                displayRank,
                style: TextStyle(color: badgeColor, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, int total, int done) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem("Tổng số việc", total.toString()),
          _verticalDivider(),
          _statItem("Đã hoàn thành", done.toString()),
          _verticalDivider(),
          _statItem("Hiệu suất", total == 0 ? "0%" : "${((done / total) * 100).toInt()}%"),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _verticalDivider() => Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1));

  Widget _buildHiddenBadgesPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text("Danh hiệu đã mở khóa", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            children: [
              Icon(Icons.lock_outline_rounded, color: Colors.grey, size: 40),
              SizedBox(height: 12),
              Text(
                "Danh hiệu của người dùng này đã bị ẩn",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesSection(BuildContext context, List<Task> tasks) {
    final completedCount = tasks.where((t) => t.isDone).length;
    final highPriorityDone = tasks.where((t) => t.isDone && (t.priority == 'High' || t.priority == 'Cao')).length;
    final studyDone = tasks.where((t) => t.isDone && (t.category == 'Study' || t.category == 'Học tập')).length;
    final workDone = tasks.where((t) => t.isDone && (t.category == 'Work' || t.category == 'Công việc')).length;
    final healthDone = tasks.where((t) => t.isDone && (t.category == 'Fitness' || t.category == 'Sức khỏe')).length;

    final List<Map<String, dynamic>> allBadges = [
      {'name': "Tân thủ tiềm năng", 'icon': Icons.egg_rounded, 'color': Colors.blueGrey, 'unlocked': completedCount >= 1},
      {'name': "Chiến binh kỷ luật", 'icon': Icons.shield, 'color': Colors.green, 'unlocked': completedCount >= 5},
      {'name': "Chuyên gia lập kế hoạch", 'icon': Icons.auto_graph_rounded, 'color': Colors.teal, 'unlocked': completedCount >= 20},
      {'name': "Bậc thầy điều phối", 'icon': Icons.account_tree_rounded, 'color': Colors.purpleAccent, 'unlocked': completedCount >= 50},
      {'name': "Huyền thoại năng suất", 'icon': Icons.workspace_premium_rounded, 'color': Colors.amber, 'unlocked': completedCount >= 100},
      {'name': "Người giải quyết khủng hoảng", 'icon': Icons.flash_on_rounded, 'color': Colors.redAccent, 'unlocked': highPriorityDone >= 20},
      {'name': "Học giả uyên bác", 'icon': Icons.menu_book_rounded, 'color': Colors.indigoAccent, 'unlocked': studyDone >= 25},
      {'name': "Cỗ máy công việc", 'icon': Icons.business_center_rounded, 'color': Colors.orangeAccent, 'unlocked': workDone >= 25},
      {'name': "Chiến binh thép", 'icon': Icons.fitness_center_rounded, 'color': Colors.greenAccent, 'unlocked': healthDone >= 15},
    ];

    final unlockedBadges = allBadges.where((b) => b['unlocked'] == true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text("Danh hiệu đã mở khóa", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: unlockedBadges.isEmpty 
            ? const Center(child: Text("Chưa có danh hiệu nào được mở khóa", style: TextStyle(color: Colors.grey, fontSize: 14)))
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 0.8,
                ),
                itemCount: unlockedBadges.length,
                itemBuilder: (context, index) {
                  final badge = unlockedBadges[index];
                  final Color color = badge['color'];
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Icon(badge['icon'], color: color, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        badge['name'],
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
        ),
      ],
    );
  }
}
