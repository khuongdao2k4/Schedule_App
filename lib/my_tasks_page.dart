import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'task_model.dart';
import 'task_service.dart';
import 'edit_task_page.dart';

const kBackgroundColor = Color(0xFF1B2333);
const kCardColor = Color(0xFF263042);
const kPriority1Color = Color(0xFFC9E8A2);
const kPriority2Color = Color(0xFF4ED9F5);
const kPriority3Color = Color(0xFFCDC1D8);

class MyTasksPage extends StatefulWidget {
  const MyTasksPage({super.key});

  @override
  State<MyTasksPage> createState() => _MyTasksPageState();
}

class _MyTasksPageState extends State<MyTasksPage> {
  final TaskService _taskService = TaskService();
  DateTime selectedDate = DateTime.now();
  late PageController _pageController;
  final int initialPage = 500;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.22,
      initialPage: initialPage,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  IconData _getTaskIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('chạy') || t.contains('run') || t.contains('thể dục')) {
      return Icons.directions_run;
    }
    if (t.contains('gym') || t.contains('tập')) return Icons.fitness_center;
    if (t.contains('học') || t.contains('bài') || t.contains('study')) {
      return Icons.book;
    }
    if (t.contains('ngủ') || t.contains('sleep')) return Icons.bed;
    if (t.contains('làm') || t.contains('work')) return Icons.work;
    if (t.contains('ăn') || t.contains('uống') || t.contains('eat')) {
      return Icons.restaurant;
    }
    if (t.contains('code') || t.contains('lập trình')) return Icons.code;
    if (t.contains('phim') || t.contains('movie')) return Icons.movie;
    if (t.contains('mua') || t.contains('shop')) return Icons.shopping_cart;
    if (t.contains('cafe')) return Icons.local_cafe;
    return Icons.assignment_outlined;
  }

  void _confirmDelete(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text("Xác nhận xóa"),
        content: Text(
          "Bạn có chắc chắn muốn xóa task \"${task.title}\" không?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Hủy",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _taskService.deleteTask(task.id!);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text(
              "Xóa",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Task task) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        reverseTransitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) {
          return EditTaskPage(task: task);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
            reverseCurve: Curves.easeInOutCubic,
          );

          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(curvedAnimation);

          final fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(curvedAnimation);

          return FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _showTaskDetail(Task task) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  task.isDone ? Icons.check : (task.iconCode != null ? IconData(task.iconCode!, fontFamily: 'MaterialIcons') : _getTaskIcon(task.title)),
                  color: kPriority1Color,
                  size: 40,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Mô tả:",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              task.description.isEmpty ? "Không có mô tả" : task.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              "Thời gian:",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${task.startTime != null ? DateFormat('HH:mm').format(task.startTime!) : '--:--'} - ${task.endTime != null ? DateFormat('HH:mm').format(task.endTime!) : '--:--'}",
              style: const TextStyle(
                fontSize: 16,
                color: kPriority2Color,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPriority1Color,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Đóng"),
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

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Tasks",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          _buildCalendarHeader(),
          const SizedBox(height: 10),
          _buildArcCalendar(),
          const SizedBox(height: 30),
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF161D2B),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(50),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: StreamBuilder<List<Task>>(
                    stream: _taskService.getTasks(user?.uid ?? ''),
                    builder: (context, snapshot) {
                      final tasks = snapshot.data ?? [];
                      final filteredTasks = tasks.where((t) {
                        if (t.dueDate == null) return false;
                        return t.dueDate!.year == selectedDate.year &&
                            t.dueDate!.month == selectedDate.month &&
                            t.dueDate!.day == selectedDate.day;
                      }).toList();

                      if (filteredTasks.isEmpty) {
                        return const Center(
                          child: Text(
                            "No tasks for this day",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      filteredTasks.sort((a, b) {
                        if (a.startTime == null || b.startTime == null) return 0;
                        return a.startTime!.compareTo(b.startTime!);
                      });

                      return ListView.builder(
                        itemCount: filteredTasks.length,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemBuilder: (context, index) =>
                            _buildTimelineTaskItem(filteredTasks[index], index),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() {
            selectedDate = picked;
            _pageController.animateToPage(
              initialPage + picked.difference(DateTime.now()).inDays,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
            );
          });
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(selectedDate),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, color: kPriority1Color),
        ],
      ),
    );
  }

  Widget _buildArcCalendar() {
    return SizedBox(
      height: 160,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            selectedDate = DateTime.now().add(
              Duration(days: index - initialPage),
            );
          });
        },
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(
            Duration(days: index - initialPage),
          );
          bool isSelected = date.day == selectedDate.day &&
              date.month == selectedDate.month &&
              date.year == selectedDate.year;

          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double page = initialPage.toDouble();
              if (_pageController.hasClients &&
                  _pageController.position.haveDimensions) {
                page = _pageController.page!;
              }

              double diff = page - index;
              double scale = (1 - (diff.abs() * 0.22)).clamp(0.0, 1.0);
              double yOffset = diff.abs() * diff.abs() * 10;

              return Center(
                child: GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Transform.translate(
                    offset: Offset(0, yOffset),
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: (scale * 2.5 - 1.5).clamp(0.3, 1.0),
                        child: Container(
                          width: 75,
                          height: 100,
                          decoration: BoxDecoration(
                            color: isSelected ? kPriority1Color : const Color(0xFF2D394D),
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: kPriority1Color.withOpacity(0.4),
                                blurRadius: 15,
                                spreadRadius: 2,
                              )
                            ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                date.day.toString(),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                              Text(
                                DateFormat('E').format(date),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? Colors.black54
                                      : Colors.white38,
                                ),
                              ),
                            ],
                          ),
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
    Color cardColor = index % 3 == 0
        ? kPriority1Color
        : (index % 3 == 1 ? kPriority2Color : kPriority3Color);

    String startTimeStr = task.startTime != null
        ? DateFormat('hh:mm a').format(task.startTime!)
        : "10:00 am";
    String endTimeStr = task.endTime != null
        ? DateFormat('hh:mm a').format(task.endTime!)
        : "02:00 pm";

    bool isExpired = !task.isDone &&
        task.endTime != null &&
        now.isAfter(task.endTime!);

    bool canToggle = task.startTime != null && task.endTime != null &&
                     now.isAfter(task.startTime!) && now.isBefore(task.endTime!);

    String status = task.isDone ? "Completed" : (isExpired ? "Expired" : "Running");
    double progress = task.isDone ? 1.0 : 0.0;

    Color statusColor = isExpired ? Colors.red.shade900 : Colors.black;
    Color currentCardColor = isExpired ? cardColor.withOpacity(0.4) : cardColor;

    // 🔥 Thay đổi Icon chính của thẻ nếu đã hoàn thành
    final IconData displayIcon = task.isDone
        ? Icons.check 
        : (task.iconCode != null 
            ? IconData(task.iconCode!, fontFamily: 'MaterialIcons') 
            : _getTaskIcon(task.title));

    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 75,
              child: Column(
                children: [
                  Text(
                    startTimeStr.toLowerCase(),
                    style: TextStyle(
                      color: isExpired ? Colors.white24 : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Expanded(child: CustomPaint(painter: DashedLinePainter())),
                  const SizedBox(height: 5),
                  Text(
                    endTimeStr.toLowerCase(),
                    style: TextStyle(
                      color: isExpired ? Colors.white24 : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipPath(
                    clipper: MyTaskCardClipper(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 60, 15, 20),
                      decoration: BoxDecoration(
                        color: currentCardColor,
                        border: isExpired
                            ? Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Transform.rotate(
                            angle: 0.785,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B2333),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Transform.rotate(
                                angle: -0.785,
                                child: Center(
                                  child: Hero(
                                    tag: 'task_icon_${task.id}',
                                    transitionOnUserGestures: true,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: Icon(
                                        displayIcon, // 🔥 Sử dụng icon check nếu task xong
                                        color: isExpired
                                            ? Colors.red.withOpacity(0.5)
                                            : cardColor,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    color: isExpired ? Colors.black54 : Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    decoration: isExpired
                                        ? TextDecoration.lineThrough
                                        : null, // 🔥 Bỏ gạch ngang nếu là task hoàn thành
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  task.description.isEmpty
                                      ? "Client project"
                                      : task.description,
                                  style: TextStyle(
                                    color: isExpired
                                        ? Colors.black38
                                        : Colors.black.withOpacity(0.6),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: isExpired
                                  ? Colors.black26
                                  : Colors.black.withOpacity(0.5),
                            ),
                            color: kCardColor,
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditDialog(task);
                              } else if (value == 'detail') {
                                _showTaskDetail(task);
                              } else if (value == 'delete') {
                                _confirmDelete(task);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'detail',
                                child: Text("Xem chi tiết"),
                              ),
                              if (!isExpired)
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text("Sửa task"),
                                ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  "Xóa task",
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    left: 15,
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 15,
                    left: 130,
                    right: 15,
                    child: Row(
                      children: [
                        _buildAvatarGroup(isExpired),
                        const Spacer(),
                        _buildProgressBar(progress, isExpired),
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

  Widget _buildAvatarGroup(bool isExpired) {
    double opacity = isExpired ? 0.3 : 1.0;
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: 30,
        width: 90,
        child: Stack(
          children: [
            _buildSingleAvatar(0, Colors.blueGrey),
            _buildSingleAvatar(18, Colors.brown),
            _buildSingleAvatar(36, Colors.blue),
            Positioned(
              left: 54,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF263042),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF161D2B),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleAvatar(double left, Color color) {
    return Positioned(
      left: left,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF161D2B),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.person,
          size: 16,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress, bool isExpired) {
    return Row(
      children: [
        Container(
          width: 55,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: isExpired
                    ? Colors.redAccent.withOpacity(0.5)
                    : Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "${(progress * 100).toInt()}%",
          style: TextStyle(
            color: isExpired ? Colors.white38 : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 0;
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class MyTaskCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double r = 25.0;
    double notchH = 45.0;
    double tabW = 115.0;
    Path path = Path();

    path.moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.lineTo(tabW - 25, 0);
    path.quadraticBezierTo(tabW, 0, tabW, notchH / 2);
    path.quadraticBezierTo(tabW, notchH, tabW + 25, notchH);
    path.lineTo(size.width - r, notchH);
    path.quadraticBezierTo(size.width, notchH, size.width, notchH + r);
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
