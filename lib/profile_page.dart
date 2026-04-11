import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'task_service.dart';
import 'task_model.dart';
import 'auth_service.dart';
import 'activity_history_page.dart';

const kBackgroundColor = Color(0xFF1B2333);
const kCardColor = Color(0xFF263042);
const kAccentColor = Color(0xFFC9E8A2);
const kTextSoft = Color(0xFF94A3B8);

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _getUserRank(int completedCount) {
    if (completedCount >= 50) return "Bậc thầy năng suất";
    if (completedCount >= 20) return "Chuyên gia lập kế hoạch";
    if (completedCount >= 5) return "Chiến binh kỷ luật";
    return "Tân thủ tiềm năng";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final TaskService taskService = TaskService();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Hồ sơ cá nhân", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // --- Header: Avatar & Rank ---
            _buildHeader(user, taskService),
            const SizedBox(height: 30),

            // --- Stats Row ---
            StreamBuilder<List<Task>>(
              stream: taskService.getTasks(user?.uid ?? ''),
              builder: (context, snapshot) {
                final tasks = snapshot.data ?? [];
                final done = tasks.where((t) => t.isDone).length;
                return _buildStatsRow(tasks.length, done);
              },
            ),
            const SizedBox(height: 35),

            // --- Menu Area ---
            _buildMenuCard(context),
            
            const SizedBox(height: 40),
            Text(
              "Tham gia từ: ${user?.metadata.creationTime != null ? DateFormat('dd/MM/yyyy').format(user!.metadata.creationTime!) : '--/--/----'}",
              style: const TextStyle(color: kTextSoft, fontSize: 13),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(User? user, TaskService taskService) {
    return StreamBuilder<List<Task>>(
      stream: taskService.getTasks(user?.uid ?? ''),
      builder: (context, snapshot) {
        final completed = (snapshot.data ?? []).where((t) => t.isDone).length;
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: kAccentColor, width: 2.5),
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: kCardColor,
                backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                child: user?.photoURL == null ? const Icon(Icons.person, size: 50, color: kAccentColor) : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? "Người dùng",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: kAccentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kAccentColor.withOpacity(0.3)),
              ),
              child: Text(
                _getUserRank(completed),
                style: const TextStyle(color: kAccentColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildStatsRow(int total, int done) {
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
        Text(label, style: const TextStyle(fontSize: 11, color: kTextSoft)),
      ],
    );
  }

  Widget _verticalDivider() => Container(width: 1, height: 30, color: Colors.white.withOpacity(0.1));

  Widget _buildMenuCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _menuTile(Icons.history_rounded, "Lịch sử hoạt động", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityHistoryPage()));
          }),
          _divider(),
          _menuTile(Icons.settings_outlined, "Cài đặt tài khoản", () {}),
          _divider(),
          _menuTile(Icons.logout_rounded, "Đăng xuất", () async {
            await AuthService().signOut();
            if (context.mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          }, isDanger: true),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, VoidCallback onTap, {bool isDanger = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDanger ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDanger ? Colors.redAccent : kAccentColor, size: 20),
      ),
      title: Text(title, style: TextStyle(color: isDanger ? Colors.redAccent : Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
      onTap: onTap,
    );
  }

  Widget _divider() => const Divider(height: 1, color: Colors.white10, indent: 60, endIndent: 20);
}
