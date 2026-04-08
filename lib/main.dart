import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'auth_service.dart';
import 'user_service.dart';
import 'task_model.dart';
import 'task_service.dart';
import 'add_task_page.dart';
import 'my_tasks_page.dart';
import 'edit_task_page.dart';

// --- Bảng màu chuẩn theo mẫu ---
const kBackgroundColor = Color(0xFF1B2333); 
const kCardColor = Color(0xFF263042); 
const kPriority1Color = Color(0xFFC9E8A2); // Xanh lá
const kPriority2Color = Color(0xFF4ED9F5); // Xanh dương
const kPriority3Color = Color(0xFFCDC1D8); // Tím nhạt
const kNavbarColor = Color(0xFF121A26); 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBackgroundColor,
        fontFamily: 'sans-serif',
      ),
      home: const LoginPage(),
    );
  }
}

//////////////////////////////////////////////////
// ================= CLIPPERS ===================
//////////////////////////////////////////////////

class PriorityCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double bevel = 35.0;
    double radius = 25.0;
    Path path = Path();
    path.moveTo(bevel, 0);
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.lineTo(0, bevel);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class TaskCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double radius = 20.0;
    double bevel = 30.0;
    Path path = Path();
    path.moveTo(radius, 0);
    path.lineTo(size.width - bevel, 0);
    path.lineTo(size.width, bevel);
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

//////////////////////////////////////////////////
// ================= LOGIN PAGE =================
//////////////////////////////////////////////////
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;

  Future<void> _handleGoogleLogin() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final user = await AuthService().signInWithGoogle();

      if (user != null) {
        await UserService().saveUser(user);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng nhập thất bại: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF031527),
      body: Stack(
        children: [
          const _SystemBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _SystemPanel(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _MissionTitle(),
                        const SizedBox(height: 28),
                        _GoogleSystemButton(
                          text: isLoading
                              ? 'ĐANG KÍCH HOẠT...'
                              : 'Login with Google',
                          onTap: isLoading ? null : _handleGoogleLogin,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'HÀNH TRÌNH CẰM NHỌN BẮT ĐẦU',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 12,
                            letterSpacing: 2.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemPanel extends StatelessWidget {
  final Widget child;

  const _SystemPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PanelPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xCC0A2740),
              Color(0xCC071D31),
              Color(0xCC0D304B),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4FD8FF).withOpacity(0.22),
              blurRadius: 40,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: const Color(0xFF8EEBFF).withOpacity(0.12),
              blurRadius: 100,
              spreadRadius: 10,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _MissionTitle extends StatelessWidget {
  const _MissionTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'NHIỆM VỤ HỆ THỐNG',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Login',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.92),
            fontSize: 17,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1.4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF8AF0FF).withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 44,
              height: 2.6,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFCBFAFF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA9F2FF).withOpacity(0.95),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                height: 1.4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8AF0FF).withOpacity(0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GoogleSystemButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _GoogleSystemButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _ButtonPainter(),
        child: Container(
          width: double.infinity,
          height: 64,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.g_mobiledata_rounded,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemBackground extends StatelessWidget {
  const _SystemBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPainter(),
            ),
          ),
          Positioned(
            top: 90,
            left: 24,
            right: 24,
            child: Container(
              height: 2.4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF63DFFF).withOpacity(0.25),
                    const Color(0xFFD6FCFF),
                    const Color(0xFF63DFFF).withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8EEFFF).withOpacity(0.75),
                    blurRadius: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const lineColor = Color(0xFFE4FDFF);
    const glowColor = Color(0xFF36CFFF);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x2A1B5D86),
          Color(0x12081B2B),
          Color(0x2A1E6C99),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, fillPaint);

    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11);

    final linePaint = Paint()
      ..color = lineColor.withOpacity(0.98)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;

    const cut = 18.0;
    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width - cut, 0)
      ..lineTo(size.width, cut)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(cut, size.height)
      ..lineTo(0, size.height - cut)
      ..lineTo(0, cut)
      ..close();

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    _corner(canvas, const Offset(0, 0), left: true, top: true);
    _corner(canvas, Offset(size.width, 0), left: false, top: true);
    _corner(canvas, Offset(0, size.height), left: true, top: false);
    _corner(canvas, Offset(size.width, size.height), left: false, top: false);

    final topAccent = Paint()
      ..color = const Color(0xFFD8FCFF).withOpacity(0.95)
      ..strokeWidth = 1.4;

    canvas.drawLine(
      const Offset(20, 0),
      Offset(size.width * 0.30, 0),
      topAccent,
    );
    canvas.drawLine(
      Offset(size.width * 0.70, 0),
      Offset(size.width - 20, 0),
      topAccent,
    );

    final sideGlow = Paint()
      ..color = const Color(0xFF59DCFF).withOpacity(0.62)
      ..strokeWidth = 2.8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

    canvas.drawLine(
      const Offset(0, 18),
      Offset(0, size.height - 18),
      sideGlow,
    );
    canvas.drawLine(
      Offset(size.width, 18),
      Offset(size.width, size.height - 18),
      sideGlow,
    );
  }

  void _corner(
      Canvas canvas,
      Offset origin, {
        required bool left,
        required bool top,
      }) {
    final glow = Paint()
      ..color = const Color(0xFF73EAFF).withOpacity(0.80)
      ..strokeWidth = 2.1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final line = Paint()
      ..color = const Color(0xFFE4FDFF).withOpacity(0.98)
      ..strokeWidth = 1.5;

    const long = 24.0;
    const short = 9.0;

    final dx = left ? 1.0 : -1.0;
    final dy = top ? 1.0 : -1.0;

    final h1 = origin + Offset(dx * short, 0);
    final h2 = origin + Offset(dx * long, 0);
    final v1 = origin + Offset(0, dy * short);
    final v2 = origin + Offset(0, dy * long);

    canvas.drawLine(h1, h2, glow);
    canvas.drawLine(v1, v2, glow);
    canvas.drawLine(h1, h2, line);
    canvas.drawLine(v1, v2, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ButtonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2E89C3),
          Color(0xFF49A9E2),
          Color(0xFF328FCA),
          Color(0xFF236B9D),
        ],
        stops: [0.0, 0.35, 0.7, 1.0],
      ).createShader(rect);

    final innerGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x88E8FEFF),
          const Color(0x22B8F3FF),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width * 0.55,
        ),
      );

    final glowPaint = Paint()
      ..color = const Color(0xFF68E7FF).withOpacity(1)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final linePaint = Paint()
      ..color = const Color(0xFFF4FFFF)
      ..strokeWidth = 1.45
      ..style = PaintingStyle.stroke;

    const cut = 16.0;
    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width - cut, 0)
      ..lineTo(size.width, cut)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(cut, size.height)
      ..lineTo(0, size.height - cut)
      ..lineTo(0, cut)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, innerGlowPaint);
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    final sideGlow = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.98)
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

    canvas.drawLine(
      Offset(12, size.height / 2),
      Offset(30, size.height / 2),
      sideGlow,
    );
    canvas.drawLine(
      Offset(size.width - 12, size.height / 2),
      Offset(size.width - 30, size.height / 2),
      sideGlow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF041628),
          Color(0xFF08233A),
          Color(0xFF041628),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), base);

    final centerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF2B8BC5).withOpacity(0.30),
          const Color(0xFF14527B).withOpacity(0.14),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width * 0.95,
        ),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      centerGlow,
    );

    final dotPaint = Paint()
      ..color = const Color(0xFFC8FAFF).withOpacity(0.18);

    for (double y = 40; y < size.height; y += 120) {
      canvas.drawCircle(Offset(28, y), 1.4, dotPaint);
      canvas.drawCircle(Offset(size.width - 28, y + 40), 1.4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

//////////////////////////////////////////////////
// ================= HOME PAGE =================
//////////////////////////////////////////////////
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TaskService _taskService = TaskService();

  IconData _getTaskIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('chạy') || t.contains('run') || t.contains('thể dục')) return Icons.directions_run;
    if (t.contains('gym') || t.contains('tập')) return Icons.fitness_center;
    if (t.contains('học') || t.contains('bài') || t.contains('study')) return Icons.book;
    if (t.contains('ngủ') || t.contains('sleep')) return Icons.bed;
    if (t.contains('làm') || t.contains('work')) return Icons.work;
    if (t.contains('ăn') || t.contains('uống') || t.contains('eat')) return Icons.restaurant;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc chắn muốn xóa task \"${task.title}\" không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
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
      backgroundColor: kBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(task.isDone ? Icons.check : (task.iconCode != null ? IconData(task.iconCode!, fontFamily: 'MaterialIcons') : _getTaskIcon(task.title)), color: kPriority1Color, size: 40),
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
                style: ElevatedButton.styleFrom(backgroundColor: kPriority1Color, foregroundColor: Colors.black),
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
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: const Icon(Icons.sort, color: Colors.white),
        title: const Text("Task Management App", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GestureDetector(
              onTap: () async {
                await AuthService().signOut();
                if (!context.mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
              },
              child: CircleAvatar(
                radius: 18,
                backgroundColor: kCardColor,
                backgroundImage: user?.photoURL != null 
                    ? NetworkImage(user!.photoURL!) 
                    : null,
                child: user?.photoURL == null 
                    ? const Icon(Icons.person, color: Colors.white, size: 20) 
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Task>>(
          stream: _taskService.getTasks(user?.uid ?? ''),
          builder: (context, snapshot) {
            final allTasks = snapshot.data ?? [];
            
            // 🔥 Lọc task chỉ trong ngày hôm nay cho On Going Task
            final todayTasks = allTasks.where((t) {
              if (t.dueDate == null) return false;
              return t.dueDate!.year == now.year &&
                     t.dueDate!.month == now.month &&
                     t.dueDate!.day == now.day;
            }).toList();

            // Sắp xếp: Task hết hạn hoặc đã xong xuống cuối
            todayTasks.sort((a, b) {
              bool aIsExpired = !a.isDone && a.endTime != null && now.isAfter(a.endTime!);
              bool bIsExpired = !b.isDone && b.endTime != null && now.isAfter(b.endTime!);
              
              if (aIsExpired != bIsExpired) return aIsExpired ? 1 : -1;
              if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
              return a.startTime?.compareTo(b.startTime ?? DateTime.now()) ?? 0;
            });

            final todoCount = allTasks.where((t) => !t.isDone).length;
            final doneCount = allTasks.where((t) => t.isDone).length;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      "Every Day Your\nTask Plan",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildPriorityCard("Chưa hoàn thành", "$todoCount task", kPriority1Color, 226, Icons.pending_actions, isLarge: true)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          children: [
                            _buildPriorityCard("Đã hoàn thành", "$doneCount task", kPriority2Color, 105, Icons.check_circle_outline),
                            const SizedBox(height: 16),
                            _buildPriorityCard("Tổng cộng", "${allTasks.length} task", kPriority3Color, 105, Icons.apps),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),
                  const Text("On Going Task", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // --- Phần danh sách Task ---
                  Expanded(
                    child: todayTasks.isEmpty
                      ? const Center(child: Text("Hôm nay chưa có task nào"))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 120),
                          itemCount: todayTasks.length,
                          itemBuilder: (context, index) {
                            final task = todayTasks[index];
                            return _buildDismissibleTaskItem(task);
                          },
                        ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      extendBody: true, 
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        height: 80,
        decoration: BoxDecoration(
          color: kNavbarColor,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(icon: const Icon(Icons.home_filled, color: kPriority1Color, size: 28), onPressed: () {}),
            IconButton(
              icon: const Icon(Icons.fact_check_outlined, color: Colors.grey, size: 28), 
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTasksPage()));
              }
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskPage()));
              },
              child: Container(
                width: 55,
                height: 55,
                decoration: const BoxDecoration(
                  color: kPriority1Color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 35),
              ),
            ),
            IconButton(icon: const Icon(Icons.auto_graph_rounded, color: Colors.grey, size: 28), onPressed: () {}),
            IconButton(icon: const Icon(Icons.person_outline, color: Colors.grey, size: 28), onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleTaskItem(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Dismissible(
        key: Key(task.id!),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          _confirmDelete(task);
          return false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete, color: Colors.white, size: 30),
        ),
        child: _buildTaskItem(task),
      ),
    );
  }

  Widget _buildPriorityCard(String title, String count, Color color, double height, IconData icon, {bool isLarge = false}) {
    Widget iconBox = Transform.rotate(
      angle: 0.785,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBackgroundColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Transform.rotate(
          angle: -0.785,
          child: Icon(icon, color: color, size: 32),
        ),
      ),
    );

    return ClipPath(
      clipper: PriorityCardClipper(),
      child: Container(
        height: height,
        width: double.infinity,
        color: color,
        padding: const EdgeInsets.all(18),
        child: isLarge 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Padding(padding: const EdgeInsets.only(top: 20), child: iconBox)),
                const Spacer(),
                Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(count, style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            )
          : Row(
              children: [
                Center(child: iconBox),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      Text(count, style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    final now = DateTime.now();
    bool isExpired = !task.isDone && task.endTime != null && now.isAfter(task.endTime!);
    // 🔥 Chỉ có thể hoàn thành nếu đang trong khoảng thời gian [startTime, endTime]
    bool canToggle = task.startTime != null && task.endTime != null && 
                     now.isAfter(task.startTime!) && now.isBefore(task.endTime!);
    
    Color taskIconColor = task.isDone ? kPriority1Color : (isExpired ? Colors.redAccent : kPriority3Color);

    return Opacity(
      opacity: isExpired ? 0.5 : 1.0,
      child: ClipPath(
        clipper: TaskCardClipper(),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: kCardColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: isExpired ? null : () {
                      if (canToggle || task.isDone) {
                        _taskService.toggleDone(task);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Chưa đến giờ thực hiện task này!"),
                            backgroundColor: Colors.orangeAccent,
                          ),
                        );
                      }
                    },
                    child: Transform.rotate(
                      angle: 0.785,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Transform.rotate(
                          angle: -0.785,
                          child: Icon(
                            task.isDone ? Icons.check : (task.iconCode != null ? IconData(task.iconCode!, fontFamily: 'MaterialIcons') : _getTaskIcon(task.title)), 
                            color: taskIconColor, 
                            size: 22
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.title, style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white,
                          decoration: isExpired ? TextDecoration.lineThrough : null,
                        )),
                        const SizedBox(height: 4),
                        Text(
                          task.startTime != null && task.endTime != null
                            ? "${DateFormat('HH:mm').format(task.startTime!)} - ${DateFormat('HH:mm').format(task.endTime!)}${isExpired ? ' (Expired)' : ''}"
                            : "No time set",
                          style: TextStyle(color: isExpired ? Colors.redAccent : Colors.grey, fontSize: 13)
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                    color: kCardColor,
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => EditTaskPage(task: task)));
                      } else if (value == 'detail') {
                        _showTaskDetail(task);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'detail', child: Text("Xem chi tiết")),
                      if (!isExpired) const PopupMenuItem(value: 'edit', child: Text("Sửa task")),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  SizedBox(
                    width: 65,
                    height: 25,
                    child: Stack(
                      children: [
                        Positioned(left: 0, child: CircleAvatar(radius: 12, backgroundColor: Colors.orange, child: const Icon(Icons.person, size: 15, color: Colors.white))),
                        Positioned(left: 18, child: CircleAvatar(radius: 12, backgroundColor: Colors.blue, child: const Icon(Icons.person, size: 15, color: Colors.white))),
                        Positioned(left: 36, child: CircleAvatar(radius: 12, backgroundColor: Colors.purple, child: const Icon(Icons.person, size: 15, color: Colors.white))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: task.isDone ? 1.0 : 0.0,
                        backgroundColor: kBackgroundColor,
                        valueColor: AlwaysStoppedAnimation<Color>(isExpired ? Colors.redAccent.withOpacity(0.5) : taskIconColor),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(task.isDone ? "100%" : "0%", style: TextStyle(color: taskIconColor, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
