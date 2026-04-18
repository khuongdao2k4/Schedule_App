import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task_model.dart';
import 'task_service.dart';
import 'user_service.dart';

class BadgeInfo {
  final String name;
  final String description;
  final Color color;
  final IconData icon;
  final bool Function(List<Task> tasks) isUnlocked;

  BadgeInfo({
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
    required this.isUnlocked,
  });
}

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  String? _selectedBadgeName;
  int? _expandedIndex;

  final List<BadgeInfo> _badges = [
    BadgeInfo(
      name: "Tân thủ tiềm năng",
      description: "Hoàn thành ít nhất 1 công việc bất kỳ.",
      color: Colors.blueGrey,
      icon: Icons.egg_rounded,
      isUnlocked: (tasks) => tasks.where((t) => t.isDone).isNotEmpty,
    ),
    BadgeInfo(
      name: "Chiến binh kỷ luật",
      description: "Hoàn thành 5 công việc.",
      color: Colors.green,
      icon: Icons.shield,
      isUnlocked: (tasks) => tasks.where((t) => t.isDone).length >= 5,
    ),
    BadgeInfo(
      name: "Chuyên gia lập kế hoạch",
      description: "Hoàn thành 20 công việc.",
      color: Colors.teal,
      icon: Icons.auto_graph_rounded,
      isUnlocked: (tasks) => tasks.where((t) => t.isDone).length >= 20,
    ),
    BadgeInfo(
      name: "Bậc thầy điều phối",
      description: "Hoàn thành 50 công việc.",
      color: Colors.purpleAccent,
      icon: Icons.account_tree_rounded,
      isUnlocked: (tasks) => tasks.where((t) => t.isDone).length >= 50,
    ),
    BadgeInfo(
      name: "Huyền thoại năng suất",
      description: "Hoàn thành 100 công việc.",
      color: Colors.amber,
      icon: Icons.workspace_premium_rounded,
      isUnlocked: (tasks) => tasks.where((t) => t.isDone).length >= 100,
    ),
    BadgeInfo(
      name: "Người giải quyết khủng hoảng",
      description: "Hoàn thành 20 công việc có độ ưu tiên 'Cao'.",
      color: Colors.redAccent,
      icon: Icons.flash_on_rounded,
      isUnlocked: (tasks) => tasks.where((t) => t.isDone && (t.priority == 'High' || t.priority == 'Cao')).length >= 20,
    ),
    BadgeInfo(
      name: "Học giả uyên bác",
      description: "Hoàn thành 25 công việc thuộc danh mục 'Học tập'.",
      color: Colors.indigoAccent,
      icon: Icons.menu_book_rounded,
      isUnlocked: (tasks) => tasks.where((t) => t.isDone && (t.category == 'Study' || t.category == 'Học tập')).length >= 25,
    ),
    BadgeInfo(
      name: "Cỗ máy công việc",
      description: "Hoàn thành 25 công việc thuộc danh mục 'Công việc'.",
      color: Colors.orangeAccent,
      icon: Icons.business_center_rounded,
      isUnlocked: (tasks) => tasks.where((t) => t.isDone && (t.category == 'Work' || t.category == 'Công việc')).length >= 25,
    ),
    BadgeInfo(
      name: "Chiến binh thép",
      description: "Hoàn thành 15 công việc thuộc danh mục 'Sức khỏe'.",
      color: Colors.greenAccent,
      icon: Icons.fitness_center_rounded,
      isUnlocked: (tasks) => tasks.where((t) => t.isDone && (t.category == 'Fitness' || t.category == 'Sức khỏe')).length >= 15,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedBadge();
  }

  Future<void> _loadSelectedBadge() async {
    final userData = await _userService.getUserData(_uid);
    if (mounted) {
      setState(() {
        _selectedBadgeName = userData?['selectedBadge'];
      });
    }
  }

  Future<void> _toggleBadge(String badgeName, bool value) async {
    final newBadge = value ? badgeName : null;
    setState(() => _selectedBadgeName = newBadge);
    await _userService.updateSelectedBadge(_uid, newBadge);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final accentColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mở khóa danh hiệu", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Task>>(
        stream: _taskService.getTasks(_uid),
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? [];
          final selectedBadgeInfo = _selectedBadgeName != null 
              ? _badges.firstWhere((b) => b.name == _selectedBadgeName, orElse: () => _badges[0])
              : null;

          return Column(
            children: [
              // --- Preview Section ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(accentColor, width: 2.5),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                        child: user?.photoURL == null ? const Icon(Icons.person, size: 40) : null,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (selectedBadgeInfo != null) 
                      _buildBadgeChip(selectedBadgeInfo)
                    else
                      const Text("Chưa chọn danh hiệu", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

              // --- Badges List ---
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _badges.length,
                  itemBuilder: (context, index) {
                    final badge = _badges[index];
                    final isUnlocked = badge.isUnlocked(tasks);
                    final isSelected = _selectedBadgeName == badge.name;
                    final isExpanded = _expandedIndex == index;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isUnlocked 
                              ? badge.color.withOpacity(isSelected ? 0.8 : 0.3) 
                              : Colors.grey.withOpacity(0.1),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(color: badge.color.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)
                        ] : [],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            onTap: () {
                              setState(() {
                                _expandedIndex = isExpanded ? null : index;
                              });
                            },
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isUnlocked ? badge.color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                badge.icon, 
                                color: isUnlocked ? badge.color : Colors.grey,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              badge.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isUnlocked ? null : Colors.grey,
                              ),
                            ),
                            trailing: isUnlocked
                                ? Switch(
                                    value: isSelected,
                                    activeColor: badge.color,
                                    onChanged: (val) => _toggleBadge(badge.name, val),
                                  )
                                : const Text("Đã khóa", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ),
                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(70, 0, 20, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(height: 1, color: Colors.white10),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Nhiệm vụ:",
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: badge.color.withOpacity(0.8)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    badge.description,
                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadgeChip(BadgeInfo badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: badge.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badge.color.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: badge.color.withOpacity(0.1), blurRadius: 8, spreadRadius: 1)
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: badge.color),
          const SizedBox(width: 6),
          Text(
            badge.name,
            style: TextStyle(color: badge.color, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
