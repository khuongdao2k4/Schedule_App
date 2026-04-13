import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

const kPriority1Color = Color(0xFFC9E8A2);
const kPriority2Color = Color(0xFF4ED9F5);
const kPriority3Color = Color(0xFFCDC1D8);
const kNavbarColor = Color(0xFF121A26);

class MyTasksPage extends StatefulWidget {
  final DateTime? initialDate;
  const MyTasksPage({super.key, this.initialDate});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  final TaskService _taskService = TaskService();
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
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc chắn muốn xóa task \"${task.title}\" không?"),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  task.isDone 
                    ? Icons.check_circle_rounded 
                    : (task.iconCode != null ? IconData(task.iconCode!, fontFamily: 'MaterialIcons') : TaskIcons.getIconByTitle(task.title)), 
                  color: kPriority1Color, size: 40
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(task.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Mô tả:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(task.description.isEmpty ? "Không có mô tả" : task.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            const Text("Thời gian:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(
              "${task.startTime != null ? DateFormat('HH:mm').format(task.startTime!) : '--:--'} - ${task.endTime != null ? DateFormat('HH:mm').format(task.endTime!) : '--:--'}, ${task.dueDate != null ? DateFormat('dd/MM/yyyy').format(task.dueDate!) : ''}", 
              style: const TextStyle(fontSize: 16, color: kPriority2Color)
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPriority1Color, 
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Đóng", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
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
          IconButton(icon: const Icon(Icons.home_filled, color: Colors.grey, size: 28), onPressed: () => Navigator.pop(context)),
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
    Color cardColor = index % 3 == 0 ? kPriority1Color : (index % 3 == 1 ? kPriority2Color : kPriority3Color);
    bool isExpired = !task.isDone && task.endTime != null && now.isAfter(task.endTime!);
    String status = task.isDone ? "Hoàn thành" : (isExpired ? "Hết hạn" : "Đang chạy");
    final IconData displayIcon = task.isDone ? Icons.check : (task.iconCode != null ? IconData(task.iconCode!, fontFamily: 'MaterialIcons') : TaskIcons.getIconByTitle(task.title));

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
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
                      padding: const EdgeInsets.fromLTRB(16, 55, 12, 16),
                      decoration: BoxDecoration(color: isExpired ? cardColor.withOpacity(0.4) : cardColor),
                      child: Row(
                        children: [
                          Transform.rotate(
                            angle: 0.785, 
                            child: Container(
                              width: 50, height: 50, 
                              decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(14)), 
                              child: Transform.rotate(angle: -0.785, child: Center(child: Icon(displayIcon, color: isExpired ? Colors.red.withOpacity(0.5) : cardColor, size: 26)))
                            )
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min, 
                              crossAxisAlignment: CrossAxisAlignment.start, 
                              children: [
                                Text(task.title, style: TextStyle(color: isExpired ? Colors.black54 : Colors.black, fontSize: 18, fontWeight: FontWeight.bold, decoration: isExpired ? TextDecoration.lineThrough : null)), 
                                const SizedBox(height: 4), 
                                Text(task.description.isEmpty ? "Nhiệm vụ hệ thống" : task.description, style: TextStyle(color: isExpired ? Colors.black38 : Colors.black.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500))
                              ]
                            )
                          ),
                          _buildModernPopupMenu(task, theme),
                        ],
                      ),
                    ),
                  ),
                  Positioned(top: 15, left: 16, child: Text(status, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold))),
                  
                  Positioned(
                    top: 2, 
                    left: 125, 
                    right: 12,
                    child: Row(
                      children: [
                        _buildSmallAvatars(context),
                        const Spacer(),
                        Container(
                          width: 85, 
                          child: Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: task.isDone ? 1.0 : 0.4, 
                                    backgroundColor: Colors.black.withOpacity(0.1), 
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B2333)), 
                                    minHeight: 6,
                                  )
                                )
                              ),
                              const SizedBox(width: 6),
                              Text(
                                task.isDone ? "100%" : "40%", 
                                style: const TextStyle(color: Color(0xFF1B2333), fontSize: 10, fontWeight: FontWeight.bold)
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
    );
  }

  Widget _buildModernPopupMenu(Task task, ThemeData theme) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black45),
      elevation: 10,
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.cardColor,
      onSelected: (val) {
        if (val == 'edit') Navigator.push(context, MaterialPageRoute(builder: (_) => EditTaskPage(task: task)));
        else if (val == 'delete') _confirmDelete(task);
        else if (val == 'detail') _showTaskDetail(task);
      },
      itemBuilder: (context) => [
        _buildPopupItem('detail', Icons.info_outline_rounded, "Xem chi tiết", Colors.blue),
        _buildPopupItem('edit', Icons.edit_outlined, "Sửa nhiệm vụ", kPriority1Color),
        const PopupMenuDivider(height: 1),
        _buildPopupItem('delete', Icons.delete_outline_rounded, "Xóa", Colors.redAccent),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String text, Color color) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSmallAvatars(BuildContext context) {
    Widget avatarCircle(int id, double left) {
      return Positioned(
        left: left,
        child: CircleAvatar(
          radius: 14,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).cardColor,
            child: ClipOval(
              child: Image.network(
                "https://api.dicebear.com/7.x/avataaars/png?seed=$id",
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 14, color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 85, height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatarCircle(1, 0),
          avatarCircle(2, 18),
          avatarCircle(3, 36),
          Positioned(
            left: 54, 
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              child: const Icon(Icons.add, size: 14)
            )
          ),
        ],
      ),
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
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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
    double shoulderWidth = size.width * 0.38;
    double curveHeight = 35;
    Path path = Path();

    path.moveTo(0, size.height - r);
    path.quadraticBezierTo(0, size.height, r, size.height);
    path.lineTo(size.width - r, size.height);
    path.quadraticBezierTo(size.width, size.height, size.width, size.height - r);
    path.lineTo(size.width, curveHeight + r);
    path.quadraticBezierTo(size.width, curveHeight, size.width - r, curveHeight);
    path.lineTo(shoulderWidth + r, curveHeight);
    path.quadraticBezierTo(shoulderWidth, curveHeight, shoulderWidth, curveHeight / 2);
    path.quadraticBezierTo(shoulderWidth, 0, shoulderWidth - r, 0);
    path.lineTo(r, 0);
    path.quadraticBezierTo(0, 0, 0, r);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
