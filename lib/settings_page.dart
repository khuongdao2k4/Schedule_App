import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'main.dart';
import 'about_page.dart';
import 'group_list_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthService().signOut();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng xuất thất bại: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Widget _buildSettingCard(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDanger
                    ? Colors.redAccent.withOpacity(0.25)
                    : Colors.white.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 6)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: iconColor.withOpacity(0.14), borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: isDanger ? Colors.redAccent : (theme.brightness == Brightness.dark ? Colors.white : Colors.black), fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: isDanger ? Colors.redAccent : Colors.grey, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Cài đặt", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 28),
              _buildSettingCard(
                context,
                icon: Icons.groups_outlined,
                iconColor: kPriority1Color,
                title: "Nhóm làm việc",
                subtitle: "Tạo nhóm và quản lý công việc chung",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupListPage()));
                },
              ),
              _buildSettingCard(
                context,
                icon: Icons.info_outline,
                iconColor: kPriority2Color,
                title: "About",
                subtitle: "Thông tin ứng dụng",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
                },
              ),
              const Spacer(),
              _buildSettingCard(
                context,
                icon: Icons.logout_rounded,
                iconColor: Colors.redAccent,
                title: "Logout",
                subtitle: "Đăng xuất tài khoản",
                isDanger: true,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: theme.cardColor,
                      title: const Text("Xác nhận"),
                      content: const Text("Bạn muốn đăng xuất?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Đăng xuất", style: TextStyle(color: Colors.redAccent))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    _handleLogout(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
