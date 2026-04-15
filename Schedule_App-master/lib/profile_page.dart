import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'task_service.dart';
import 'task_model.dart';
import 'auth_service.dart';
import 'user_service.dart';
import 'activity_history_page.dart';
import 'account_settings_page.dart';
import 'badges_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // Giữ lại logic cũ để làm mặc định nếu người dùng chưa chọn danh hiệu
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
    final user = FirebaseAuth.instance.currentUser;
    final TaskService taskService = TaskService();
    final UserService userService = UserService();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.brightness == Brightness.dark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Hồ sơ cá nhân", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Task>>(
        stream: taskService.getTasks(user?.uid ?? ''),
        builder: (context, taskSnapshot) {
          final tasks = taskSnapshot.data ?? [];
          final doneTasks = tasks.where((t) => t.isDone).toList();
          
          return FutureBuilder<Map<String, dynamic>?>(
            future: userService.getUserData(user?.uid ?? ''),
            builder: (context, userSnapshot) {
              final userData = userSnapshot.data;
              final selectedBadge = userData?['selectedBadge'];

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // --- Header: Avatar & Rank ---
                    _buildHeader(context, user, selectedBadge, tasks),
                    const SizedBox(height: 30),

                    // --- Stats Row ---
                    _buildStatsRow(context, tasks.length, doneTasks.length),
                    const SizedBox(height: 35),

                    // --- Menu Area ---
                    _buildMenuCard(context),
                    
                    const SizedBox(height: 40),
                    Text(
                      "Tham gia từ: ${user?.metadata.creationTime != null ? DateFormat('dd/MM/yyyy').format(user!.metadata.creationTime!) : '--/--/----'}",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
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

  Widget _buildHeader(BuildContext context, User? user, String? selectedBadge, List<Task> tasks) {
    final accentColor = Theme.of(context).primaryColor;
    
    // Tìm màu cho badge nếu là badge hệ thống đã chọn
    Color badgeColor = accentColor;
    String displayRank = selectedBadge ?? _getDefaultRank(tasks);
    
    // Mapping màu sắc cơ bản cho các danh hiệu phổ biến
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
            border: Border.all(color: accentColor, width: 2.5),
          ),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Theme.of(context).cardColor,
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null ? Icon(Icons.person, size: 50, color: accentColor) : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user?.displayName ?? "Người dùng",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(context, "Tổng số việc", total.toString()),
          _verticalDivider(),
          _statItem(context, "Đã hoàn thành", done.toString()),
          _verticalDivider(),
          _statItem(context, "Hiệu suất", total == 0 ? "0%" : "${((done / total) * 100).toInt()}%"),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _verticalDivider() => Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1));

  Widget _buildMenuCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _menuTile(context, Icons.workspace_premium_outlined, "Mở khóa danh hiệu", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgesPage()));
          }),
          _divider(),
          _menuTile(context, Icons.history_rounded, "Lịch sử hoạt động", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityHistoryPage()));
          }),
          _divider(),
          _menuTile(context, Icons.settings_outlined, "Cài đặt tài khoản", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountSettingsPage()));
          }),
          _divider(),
          _menuTile(context, Icons.logout_rounded, "Đăng xuất", () async {
            await AuthService().signOut();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          }, isDanger: true),
        ],
      ),
    );
  }

  Widget _menuTile(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isDanger = false}) {
    final accentColor = Theme.of(context).primaryColor;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDanger ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDanger ? Colors.redAccent : accentColor, size: 20),
      ),
      title: Text(title, style: TextStyle(color: isDanger ? Colors.redAccent : null, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      onTap: onTap,
    );
  }

  Widget _divider() => const Divider(height: 1, color: Colors.white10, indent: 60, endIndent: 20);
}
