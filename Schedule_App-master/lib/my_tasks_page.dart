import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'task_model.dart';
import 'task_service.dart';
import 'edit_task_page.dart';
import 'statistics_page.dart';
import 'settings_page.dart';
import 'add_task_page.dart';
import 'profile_page.dart';
import 'task_icons.dart';
import 'calendar_page.dart';
import 'user_service.dart';
import 'task_detail_page.dart';

const kPriority1Color = Color(0xFFC9E8A2);
const kPriority2Color = Color(0xFF4ED9F5);
const kPriority3Color = Color(0xFFCDC1D8);
const kNavbarColor = Color(0xFF121A26);
const kCardColor = Color(0xFF263042);

class MyTasksPage extends StatefulWidget {
  final DateTime? initialDate;
  const MyTasksPage({super.key, this.initialDate});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();
  late DateTime selectedDate;
  late PageController _pageController;
  final int initialPage = 5000; 
  
  final DateTime baseDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @override
  void initState() {
    super.initState();
    DateTime rawDate = widget.initialDate ?? DateTime.now();
    selectedDate = DateTime(rawDate.year, rawDate.month, rawDate.day);
    
    int dayDifference = selectedDate.difference(baseDate).inDays;
    
    _pageController = PageController(
      viewportFraction: 0.22, 
      initialPage: initialPage + dayDifference,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _confirmDelete(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xác nhận xóa", style: TextStyle(color: Colors.white)),
        content: Text("Bạn có chắc chắn muốn xóa task \"${task.title}\" không?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              await _taskService.deleteTask(task.id!);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTaskDetail(Task task) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)));
  }

  void _showAddMemberDialog(Task task) {
    final TextEditingController emailController = TextEditingController();
    bool isAdding = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: kCardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Thêm thành viên", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Nhập email của người bạn muốn thêm vào nhiệm vụ này.", style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(14)),
                child: TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Email...",
                    hintStyle: TextStyle(color: Colors.white24),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
            TextButton(
              onPressed: isAdding ? null : () async {
                final email = emailController.text.trim().toLowerCase();
                if (email.isEmpty) return;

                setDialogState(() => isAdding = true);
                try {
                  final userData = await _userService.getUserByEmail(email);
                  if (userData == null) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không tìm thấy người dùng!")));
                  } else {
                    final uid = userData['uid'] as String;
                    if (task.assignees.contains(uid)) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Người dùng đã tham gia rồi!")));
                    } else {
                      List<String> newAssignees = List.from(task.assignees)..add(uid);
                      await _taskService.updateTask(task.copyWith(assignees: newAssignees));
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm thành viên!"), backgroundColor: Colors.green));
                      }
                    }
                  }
                } catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi khi thêm thành viên")));
                } finally {
                  setDialogState(() => isAdding = false);
                }
              },
              child: isAdding 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kPriority2Color))
                : const Text("Thêm", style: TextStyle(color: kPriority2Color, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const SettingsPage(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.calendar_month_outlined), 
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarPage()));
          }
        ),
        title: const Text("My Tasks", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 10),
              _buildCalendarHeader(),
              const SizedBox(height: 120), 
              Expanded(
                child: ClipPath(
                  clipper: DomeClipper(),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: theme.brightness == Brightness.dark ? const Color(0xFF161D2B) : Colors.grey[200]),
                    child: StreamBuilder<List<Task>>(
                      stream: _taskService.getTasks(user?.uid ?? ''),
                      builder: (context, snapshot) {
                        final tasks = snapshot.data ?? [];
                        final filteredTasks = tasks.where((t) {
                          if (t.dueDate == null) return false;
                          return t.dueDate!.year == selectedDate.year && t.dueDate!.month == selectedDate.month && t.dueDate!.day == selectedDate.day;
                        }).toList();

                        if (filteredTasks.isEmpty) return const Center(child: Text("Không có nhiệm vụ cho ngày này", style: TextStyle(color: Colors.grey)));

                        filteredTasks.sort((a, b) => (a.startTime ?? DateTime.now()).compareTo(b.startTime ?? DateTime.now()));

                        return ListView.builder(
                          itemCount: filteredTasks.length,
                          padding: const EdgeInsets.fromLTRB(10, 110, 10, 100),
                          itemBuilder: (context, index) => _buildTimelineTaskItem(filteredTasks[index], index),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: _buildArcCalendar(),
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _buildNavbar(context),
    );
  }

  Widget _buildNavbar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      height: 80,
      decoration: BoxDecoration(color: kNavbarColor, borderRadius: BorderRadius.circular(40), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.home_filled, color: Colors.grey, size: 28), 
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst)
          ),
          IconButton(icon: const Icon(Icons.fact_check_outlined, color: kPriority1Color, size: 28), onPressed: () {}),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskPage())),
            child: Container(width: 55, height: 55, decoration: const BoxDecoration(color: kPriority1Color, shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.black, size: 35)),
          ),
          IconButton(icon: const Icon(Icons.auto_graph_rounded, color: Colors.grey, size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsPage()))),
          IconButton(icon: const Icon(Icons.person_outline, color: Colors.grey, size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(DateFormat('MMMM yyyy').format(selectedDate), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(width: 5),
        const Icon(Icons.keyboard_arrow_down, size: 20),
      ],
    );
  }

  Widget _buildArcCalendar() {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            selectedDate = baseDate.add(Duration(days: index - initialPage));
          });
        },
        itemBuilder: (context, index) {
          DateTime date = baseDate.add(Duration(days: index - initialPage));
          bool isSelected = date.day == selectedDate.day && date.month == selectedDate.month && date.year == selectedDate.year;
          
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double targetPage = initialPage.toDouble() + selectedDate.difference(baseDate).inDays;
              double page = _pageController.hasClients ? (_pageController.page ?? targetPage) : targetPage;
              double diff = page - index;
              
              double yOffset = math.pow(diff.abs(), 2) * 15;
              double scale = (1 - (diff.abs() * 0.15)).clamp(0.0, 1.0);
              
              return Center(
                child: Transform.translate(
                  offset: Offset(0, yOffset),
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: (scale * 2.5 - 1.5).clamp(0.4, 1.0),
                      child: Container(
                        width: 70, height: 100,
                        decoration: BoxDecoration(
                          color: isSelected ? kPriority1Color : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2D394D) : Colors.white), 
                          borderRadius: BorderRadius.circular(35), 
                          boxShadow: isSelected ? [] : [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(date.day.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black))),
                            Text(DateFormat('E').format(date), style: TextStyle(fontSize: 14, color: isSelected ? Colors.black54 : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTimelineTaskItem(Task task, int index) {
    final now = DateTime.now();
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    Color cardColor = index % 3 == 0 ? kPriority1Color : (index % 3 == 1 ? kPriority2Color : kPriority3Color);
    
    // Kiểm tra user hiện tại đã hoàn thành chưa
    bool isUserDone = task.completedBy.contains(user?.uid);
    
    bool isExpired = !isUserDone && task.endTime != null && now.isAfter(task.endTime!);
    bool isStarted = task.startTime == null || now.isAfter(task.startTime!);
    
    // 🔥 Phân biệt rõ Creator và Member
    bool isCreator = user != null && task.userId == user.uid;
    bool hasAccepted = user != null && task.acceptedBy.contains(user.uid);
    
    // Chỉ hiển thị là "Lời mời" nếu là thành viên nhưng KHÔNG PHẢI người tạo và CHƯA đồng ý
    bool showAsInvitation = !isCreator && !hasAccepted;

    String status = isUserDone ? "Hoàn thành" : (isExpired ? "Hết hạn" : (isStarted ? "Đang chạy" : "Chưa tới giờ"));
    if (showAsInvitation) status = "Lời mời";

    double progress = task.assignees.isEmpty ? (task.isDone ? 1.0 : 0.0) : (task.completedBy.length / task.assignees.length);
    
    IconData displayIcon;
    if (isUserDone) {
      displayIcon = Icons.check_circle_rounded;
    } else if (task.iconCode != null) {
      displayIcon = IconData(task.iconCode!, fontFamily: 'MaterialIcons');
    } else {
      displayIcon = TaskIcons.getIconByTitle(task.title);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Opacity(
        opacity: (isExpired || showAsInvitation) && !isUserDone ? 0.6 : 1.0,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 75, child: Column(children: [
                Text(task.startTime != null ? DateFormat('HH:mm').format(task.startTime!) : "10:00", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Expanded(child: CustomPaint(painter: DashedLinePainter(color: theme.dividerColor))),
                const SizedBox(height: 5),
                Text(task.endTime != null ? DateFormat('HH:mm').format(task.endTime!) : "12:00", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ])),
              const SizedBox(width: 15),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipPath(
                      clipper: MyTaskCardClipper(),
                      child: Container(
                        width: double.infinity, 
                        padding: const EdgeInsets.fromLTRB(16, 50, 12, 16),
                        decoration: BoxDecoration(color: (isExpired && !isUserDone) ? cardColor.withOpacity(0.4) : cardColor),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (showAsInvitation) return;
                                if (isExpired && !isUserDone) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Nhiệm vụ đã hết hạn, không thể hoàn thành!"), duration: Duration(seconds: 2))
                                  );
                                  return;
                                }
                                if (!isStarted && !isUserDone) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Nhiệm vụ chưa tới thời gian bắt đầu!"), duration: Duration(seconds: 2))
                                  );
                                  return;
                                }
                                _taskService.toggleDone(task);
                              },
                              child: Transform.rotate(
                                angle: 0.785, 
                                child: Container(
                                  width: 50, height: 50, 
                                  decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(14)), 
                                  child: Transform.rotate(angle: -0.785, child: Center(child: Icon(displayIcon, color: isUserDone ? kPriority1Color : (isExpired ? Colors.red.withOpacity(0.5) : (isStarted ? cardColor : Colors.white24)), size: 26)))
                                )
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => !showAsInvitation ? _showTaskDetail(task) : null,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min, 
                                  crossAxisAlignment: CrossAxisAlignment.start, 
                                  children: [
                                    Text(task.title, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    if (task.groupId != null) ...[
                                      _GroupBadge(groupId: task.groupId!),
                                      const SizedBox(height: 4),
                                    ],
                                    Text(task.description.isEmpty ? "Nhiệm vụ hệ thống" : task.description, style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500))
                                  ]
                                ),
                              )
                            ),
                            _buildModernPopupMenu(task, theme, isExpired, showAsInvitation, isUserDone),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12, 
                      left: 16, 
                      child: Text(status, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    
                    Positioned(
                      top: 0, 
                      left: 125, 
                      right: 12,
                      child: Row(
                        children: [
                          UserAvatarStack(
                            uids: task.assignees, 
                            size: 28, 
                            cardColor: cardColor,
                            onAddTap: () => _showAddMemberDialog(task),
                          ),
                          const Spacer(),
                          Container(
                            width: 100, 
                            child: Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: progress, 
                                      backgroundColor: Colors.white.withOpacity(0.2), 
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), 
                                      minHeight: 6,
                                    )
                                  )
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${(progress * 100).toInt()}%", 
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernPopupMenu(Task task, ThemeData theme, bool isExpired, bool showAsInvitation, bool isUserDone) {
    final user = FirebaseAuth.instance.currentUser;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black45),
      elevation: 10,
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFF2E3A4F),
      onSelected: (val) async {
        if (val == 'accept') {
          if (user != null && task.id != null) {
            await _taskService.acceptTask(task.id!, user.uid);
          }
        } else if (val == 'reject') {
          if (user != null && task.id != null) {
            await _taskService.rejectTask(task.id!, user.uid);
          }
        } else if (val == 'edit') {
          if (isExpired && !isUserDone) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Nhiệm vụ đã hết hạn, không thể sửa!"), duration: Duration(seconds: 2))
            );
            return;
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => EditTaskPage(task: task)));
        }
        else if (val == 'delete') _confirmDelete(task);
        else if (val == 'detail') _showTaskDetail(task);
      },
      itemBuilder: (context) {
        // 🔥 Nếu là lời mời, chỉ hiện Đồng ý/Từ chối
        if (showAsInvitation) {
          return [
            _buildPopupItem('accept', Icons.check_circle_outline, "Đồng ý", Colors.greenAccent),
            _buildPopupItem('reject', Icons.cancel_outlined, "Từ chối", Colors.redAccent),
          ];
        }
        // 🔥 Ngược lại hiển thị menu quản lý bình thường
        return [
          _buildPopupItem('detail', Icons.info_outline_rounded, "Chi tiết", Colors.white70),
          _buildPopupItem('edit', Icons.edit_outlined, "Sửa nhiệm vụ", (isExpired && !isUserDone) ? Colors.grey : Colors.white70),
          const PopupMenuDivider(height: 1),
          _buildPopupItem('delete', Icons.delete_outline_rounded, "Xóa", Colors.redAccent),
        ];
      },
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String text, Color color) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}

class _GroupBadge extends StatelessWidget {
  final String groupId;
  const _GroupBadge({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('groups').doc(groupId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final groupName = snapshot.data?['name'] ?? 'Nhóm';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.08),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.groups_rounded, size: 12, color: Colors.black54),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  groupName,
                  style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold),
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

class UserAvatarStack extends StatelessWidget {
  final List<String> uids;
  final double size;
  final Color cardColor;
  final VoidCallback onAddTap;
  const UserAvatarStack({super.key, required this.uids, this.size = 24, required this.cardColor, required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    if (uids.isEmpty) return const SizedBox.shrink();
    int displayCount = uids.length > 2 ? 2 : uids.length;
    
    return SizedBox(
      width: (displayCount * (size * 0.75)) + 35,
      height: size + 4,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < displayCount; i++)
            Positioned(
              left: i * (size * 0.75),
              child: _SingleUserAvatar(uid: uids[i], size: size, cardColor: cardColor),
            ),
          if (uids.length > 2)
            Positioned(
              left: displayCount * (size * 0.75),
              child: Container(
                width: size, height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Colors.grey.shade800,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text("+${uids.length - 2}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
              ),
            )
          else
            Positioned(
              left: displayCount * (size * 0.75),
              child: GestureDetector(
                onTap: onAddTap,
                child: Container(
                  width: size, height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Colors.white.withOpacity(0.3),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.add, size: 14, color: Colors.white)
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SingleUserAvatar extends StatelessWidget {
  final String uid;
  final double size;
  final Color cardColor;
  const _SingleUserAvatar({required this.uid, required this.size, required this.cardColor});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: UserService().getUserData(uid),
      builder: (context, snapshot) {
        String? photoUrl = snapshot.data?['photo'];
        return Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            color: Colors.grey.shade800,
          ),
          child: ClipOval(
            child: photoUrl != null
                ? Image.network(
                    photoUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.person, size: size * 0.6, color: Colors.white54),
                  )
                : Icon(Icons.person, size: size * 0.6, color: Colors.white54),
          ),
        );
      },
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()..color = color.withOpacity(0.3)..strokeWidth = 1;
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width / 2, startY), Offset(size.width / 2, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DomeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 100);
    path.quadraticBezierTo(size.width / 2, -30, size.width, 100);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class MyTaskCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double r = 24;
    double shoulderWidth = 115; // Độ rộng của phần "Dang chay"
    double curveHeight = 35;
    Path path = Path();

    path.moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.lineTo(shoulderWidth - r, 0);
    path.quadraticBezierTo(shoulderWidth, 0, shoulderWidth, r);
    path.lineTo(shoulderWidth, curveHeight - r);
    path.quadraticBezierTo(shoulderWidth, curveHeight, shoulderWidth + r, curveHeight);
    path.lineTo(size.width - r, curveHeight);
    path.quadraticBezierTo(size.width, curveHeight, size.width, curveHeight + r);
    path.lineTo(size.width, size.height - r);
    path.quadraticBezierTo(size.width, size.height, size.width - r, size.height);
    path.lineTo(r, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - r);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
