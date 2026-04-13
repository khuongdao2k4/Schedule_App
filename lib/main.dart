import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'theme_provider.dart';
import 'task_service.dart';
import 'user_service.dart';
import 'task_model.dart';
import 'add_task_page.dart';
import 'my_tasks_page.dart';
import 'edit_task_page.dart';
import 'settings_page.dart';
import 'statistics_page.dart';
import 'profile_page.dart';
import 'task_icons.dart';

// --- Màu sắc chuẩn ---
const kBackgroundColor = Color(0xFF1B2333); 
const kCardColor = Color(0xFF263042); 
const kPriority1Color = Color(0xFFC9E8A2); 
const kPriority2Color = Color(0xFF4ED9F5); 
const kPriority3Color = Color(0xFFCDC1D8); 
const kNavbarColor = Color(0xFF121A26); 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.currentTheme,
      locale: const Locale('vi', 'VN'),
      home: FirebaseAuth.instance.currentUser != null 
          ? const HomePage() 
          : const LoginPage(),
    );
  }
}

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
    double r = 24.0;
    double sh = 14.0; // Độ sâu lõm xuống
    double sw = 50.0; // Độ rộng của phần nhô lên ở hai đầu
    double slant = 15.0;
    
    Path path = Path();
    path.moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.lineTo(sw, 0);
    path.lineTo(sw + slant, sh);
    path.lineTo(size.width - sw - slant, sh);
    path.lineTo(size.width - sw, 0);
    path.lineTo(size.width - r, 0);
    path.quadraticBezierTo(size.width, 0, size.width, r);
    path.lineTo(size.width, size.height - r);
    path.quadraticBezierTo(size.width, size.height, size.width - r, size.height);
    path.lineTo(r, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - r);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;

  Future<void> _handleGoogleLogin() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final user = await AuthService().signInWithGoogle();
      if (user != null) {
        await UserService().saveUser(user);
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đăng nhập thất bại: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => isLoading = false);
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
                          text: isLoading ? 'ĐANG KÍCH HOẠT...' : 'Login with Google',
                          onTap: isLoading ? null : _handleGoogleLogin,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'HÀNH TRÌNH CẰM NHỌN BẮT ĐẦU',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.72), fontSize: 12, letterSpacing: 2.6),
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
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xCC0A2740), Color(0xCC071D31), Color(0xCC0D304B)],
            stops: [0.0, 0.45, 1.0],
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFF4FD8FF).withOpacity(0.22), blurRadius: 40, spreadRadius: 2),
            BoxShadow(color: const Color(0xFF8EEBFF).withOpacity(0.12), blurRadius: 100, spreadRadius: 10),
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
        const Text('NHIỆM VỤ HỆ THỐNG', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w700, letterSpacing: 2.8)),
        const SizedBox(height: 10),
        Text('Login', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 17, fontWeight: FontWeight.w500, letterSpacing: 1.1)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: Container(height: 1.4, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, const Color(0xFF8AF0FF).withOpacity(0.85)])))),
            Container(width: 44, height: 2.6, margin: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: const Color(0xFFCBFAFF), boxShadow: [BoxShadow(color: const Color(0xFFA9F2FF).withOpacity(0.95), blurRadius: 10)])),
            Expanded(child: Container(height: 1.4, decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF8AF0FF).withOpacity(0.85), Colors.transparent])))),
          ],
        ),
      ],
    );
  }
}

class _GoogleSystemButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  const _GoogleSystemButton({required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _ButtonPainter(),
        child: Container(
          width: double.infinity, height: 64, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 34),
              const SizedBox(width: 10),
              Flexible(child: Text(text, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: 0.8))),
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
          Positioned.fill(child: CustomPaint(painter: _BackgroundPainter())),
          Positioned(
            top: 90, left: 24, right: 24,
            child: Container(
              height: 2.4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, const Color(0xFF63DFFF).withOpacity(0.25), const Color(0xFFD6FCFF), const Color(0xFF63DFFF).withOpacity(0.25), Colors.transparent]),
                boxShadow: [BoxShadow(color: const Color(0xFF8EEFFF).withOpacity(0.75), blurRadius: 22)],
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
    final fillPaint = Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x2A1B5D86), Color(0x12081B2B), Color(0x2A1E6C99)]).createShader(rect);
    canvas.drawRect(rect, fillPaint);
    final glowPaint = Paint()..color = glowColor.withOpacity(0.82)..style = PaintingStyle.stroke..strokeWidth = 2.4..maskFilter = const MaskFilter.blur(BlurStyle.normal, 11);
    final linePaint = Paint()..color = lineColor.withOpacity(0.98)..style = PaintingStyle.stroke..strokeWidth = 1.25;
    const cut = 18.0;
    final path = Path()..moveTo(cut, 0)..lineTo(size.width - cut, 0)..lineTo(size.width, cut)..lineTo(size.width, size.height - cut)..lineTo(size.width - cut, size.height)..lineTo(cut, size.height)..lineTo(0, size.height - cut)..lineTo(0, cut)..close();
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
    _corner(canvas, const Offset(0, 0), left: true, top: true);
    _corner(canvas, Offset(size.width, 0), left: false, top: true);
    _corner(canvas, Offset(0, size.height), left: true, top: false);
    _corner(canvas, Offset(size.width, size.height), left: false, top: false);
    final topAccent = Paint()..color = const Color(0xFFD8FCFF).withOpacity(0.95)..strokeWidth = 1.4;
    canvas.drawLine(const Offset(20, 0), Offset(size.width * 0.30, 0), topAccent);
    canvas.drawLine(Offset(size.width * 0.70, 0), Offset(size.width - 20, 0), topAccent);
    final sideGlow = Paint()..color = const Color(0xFF59DCFF).withOpacity(0.62)..strokeWidth = 2.8..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawLine(const Offset(0, 18), Offset(0, size.height - 18), sideGlow);
    canvas.drawLine(Offset(size.width, 18), Offset(size.width, size.height - 18), sideGlow);
  }
  void _corner(Canvas canvas, Offset origin, {required bool left, required bool top}) {
    final glow = Paint()..color = const Color(0xFF73EAFF).withOpacity(0.80)..strokeWidth = 2.1..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final line = Paint()..color = const Color(0xFFE4FDFF).withOpacity(0.98)..strokeWidth = 1.5;
    const long = 24.0; const short = 9.0;
    final dx = left ? 1.0 : -1.0; final dy = top ? 1.0 : -1.0;
    final h1 = origin + Offset(dx * short, 0); final h2 = origin + Offset(dx * long, 0);
    final v1 = origin + Offset(0, dy * short); final v2 = origin + Offset(0, dy * long);
    canvas.drawLine(h1, h2, glow); canvas.drawLine(v1, v2, glow);
    canvas.drawLine(h1, h2, line); canvas.drawLine(v1, v2, line);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ButtonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final fillPaint = Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2E89C3), Color(0xFF49A9E2), Color(0xFF328FCA), Color(0xFF236B9D)], stops: [0.0, 0.35, 0.7, 1.0]).createShader(rect);
    final innerGlowPaint = Paint()..shader = const RadialGradient(colors: [Color(0x88E8FEFF), Color(0x22B8F3FF), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width * 0.55));
    final glowPaint = Paint()..color = const Color(0xFF68E7FF).withOpacity(1)..strokeWidth = 2.8..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final linePaint = Paint()..color = const Color(0xFFF4FFFF)..strokeWidth = 1.45..style = PaintingStyle.stroke;
    const cut = 16.0;
    final path = Path()..moveTo(cut, 0)..lineTo(size.width - cut, 0)..lineTo(size.width, cut)..lineTo(size.width, size.height - cut)..lineTo(size.width - cut, size.height)..lineTo(cut, size.height)..lineTo(0, size.height - cut)..lineTo(0, cut)..close();
    canvas.drawPath(path, fillPaint); canvas.drawPath(path, innerGlowPaint); canvas.drawPath(path, glowPaint); canvas.drawPath(path, linePaint);
    final sideGlow = Paint()..color = const Color(0xFFFFFFFF).withOpacity(0.98)..strokeWidth = 2.0..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    canvas.drawLine(Offset(12, size.height / 2), Offset(30, size.height / 2), sideGlow);
    canvas.drawLine(Offset(size.width - 12, size.height / 2), Offset(size.width - 30, size.height / 2), sideGlow);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF041628), Color(0xFF08233A), Color(0xFF041628)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), base);
    final centerGlow = Paint()..shader = RadialGradient(colors: [const Color(0xFF2B8BC5).withOpacity(0.30), const Color(0xFF14527B).withOpacity(0.14), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width * 0.95));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), centerGlow);
    final dotPaint = Paint()..color = const Color(0xFFC8FAFF).withOpacity(0.18);
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
          TextButton(onPressed: () async {
            await _taskService.deleteTask(task.id!);
            if (!mounted) return;
            Navigator.pop(context);
          }, child: const Text("Xóa", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();

    return Scaffold(
      drawer: const SettingsPage(),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: Builder(builder: (context) => IconButton(icon: Icon(Icons.settings_outlined, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black), onPressed: () => Scaffold.of(context).openDrawer())),
        title: const Text("Task Management App", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)), centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
              child: CircleAvatar(
                radius: 18, backgroundColor: Theme.of(context).cardColor,
                child: ClipOval(
                  child: user?.photoURL != null 
                    ? Image.network(
                        user!.photoURL!,
                        fit: BoxFit.cover,
                        width: 36, height: 36,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white, size: 20),
                      )
                    : const Icon(Icons.person, color: Colors.white, size: 20),
                ),
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
            final todayTasks = allTasks.where((t) {
              if (t.dueDate == null) return false;
              return t.dueDate!.year == now.year && t.dueDate!.month == now.month && t.dueDate!.day == now.day;
            }).toList();
            todayTasks.sort((a, b) {
              bool aEx = !a.isDone && a.endTime != null && now.isAfter(a.endTime!);
              bool bEx = !b.isDone && b.endTime != null && now.isAfter(b.endTime!);
              if (aEx != bEx) return aEx ? 1 : -1;
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
                  const Center(child: Text("Every Day Your\nTask Plan", textAlign: TextAlign.center, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, height: 1.2))),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      Expanded(child: _buildPriorityCard("Chưa xong", "$todoCount task", kPriority1Color, 226, Icons.pending_actions, isLarge: true)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          children: [
                            _buildPriorityCard("Hoàn thành", "$doneCount task", kPriority2Color, 105, Icons.check_circle_outline),
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
                  Expanded(
                    child: todayTasks.isEmpty ? const Center(child: Text("Hôm nay chưa có task nào")) : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 120), itemCount: todayTasks.length,
                      itemBuilder: (context, index) => _buildTaskItem(todayTasks[index]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      extendBody: true,
      bottomNavigationBar: _buildBottomNavbar(context),
    );
  }

  Widget _buildBottomNavbar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30), height: 80,
      decoration: BoxDecoration(color: kNavbarColor, borderRadius: BorderRadius.circular(40)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(icon: const Icon(Icons.home_filled, color: kPriority1Color, size: 28), onPressed: () {}),
          IconButton(icon: const Icon(Icons.fact_check_outlined, color: Colors.grey, size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTasksPage()))),
          GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTaskPage())), child: Container(width: 55, height: 55, decoration: const BoxDecoration(color: kPriority1Color, shape: BoxShape.circle), child: const Icon(Icons.add, color: Colors.black, size: 35))),
          IconButton(icon: const Icon(Icons.auto_graph_rounded, color: Colors.grey, size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsPage()))),
          IconButton(icon: const Icon(Icons.person_outline, color: Colors.grey, size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
        ],
      ),
    );
  }

  Widget _buildPriorityCard(String title, String count, Color color, double height, IconData icon, {bool isLarge = false}) {
    return ClipPath(
      clipper: PriorityCardClipper(),
      child: Container(
        height: height, padding: const EdgeInsets.all(18), color: color,
        child: isLarge ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Icon(icon, color: Colors.black54, size: 40)), const Spacer(),
          Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(count, style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 14)),
        ]) : Row(children: [
          Icon(icon, color: Colors.black54, size: 30), const SizedBox(width: 12),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
            Text(count, style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 12)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    final now = DateTime.now();
    bool isEx = !task.isDone && task.endTime != null && now.isAfter(task.endTime!);
    double progress = task.isDone ? 1.0 : (task.actualMinutes / (task.estimatedMinutes > 0 ? task.estimatedMinutes : 30)).clamp(0.0, 1.0);
    
    IconData taskIcon;
    if (task.isDone) {
      taskIcon = Icons.check_circle_rounded;
    } else if (task.iconCode != null) {
      taskIcon = IconData(task.iconCode!, fontFamily: 'MaterialIcons');
    } else {
      taskIcon = TaskIcons.getIconByTitle(task.title);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Dismissible(
        key: Key(task.id ?? task.title),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: kCardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Xác nhận xóa", style: TextStyle(color: Colors.white)),
              content: Text("Bạn có chắc chắn muốn xóa task \"${task.title}\" không?", style: const TextStyle(color: Colors.white70)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xóa", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
              ],
            ),
          );
        },
        onDismissed: (direction) => _taskService.deleteTask(task.id!),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 30),
        ),
        child: ClipPath(
          clipper: TaskCardClipper(),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: kCardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _taskService.toggleDone(task),
                      child: SizedBox(
                        width: 50, height: 50,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.rotate(
                              angle: 0.785,
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: task.isDone ? kPriority1Color.withOpacity(0.2) : kBackgroundColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: task.isDone ? kPriority1Color : Colors.white10, width: 1),
                                ),
                              ),
                            ),
                            Icon(taskIcon, color: task.isDone ? kPriority1Color : kPriority2Color, size: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
                              decoration: task.isDone ? TextDecoration.lineThrough : (isEx ? TextDecoration.lineThrough : null),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.category,
                            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    ),
                    Theme(
                      data: Theme.of(context).copyWith(
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white54),
                        color: const Color(0xFF2E3A4F),
                        elevation: 10,
                        offset: const Offset(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => EditTaskPage(task: task)));
                          } else if (value == 'delete') {
                            _confirmDelete(task);
                          } else if (value == 'detail') {
                            // TODO: Mở trang chi tiết
                          }
                        },
                        itemBuilder: (context) => [
                          _buildPopupItem('detail', Icons.info_outline, "Chi tiết", Colors.white70),
                          _buildPopupItem('edit', Icons.edit_outlined, "Sửa", Colors.white70),
                          const PopupMenuDivider(height: 1),
                          _buildPopupItem('delete', Icons.delete_outline, "Xóa", Colors.redAccent.withOpacity(0.8)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 70, height: 30,
                      child: Stack(
                        children: [
                          _buildAvatar(0, "https://i.pravatar.cc/150?u=1"),
                          _buildAvatar(15, "https://i.pravatar.cc/150?u=2"),
                          _buildAvatar(30, "https://i.pravatar.cc/150?u=3"),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(task.isDone ? kPriority1Color : kPriority2Color),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: TextStyle(color: task.isDone ? kPriority1Color : kPriority2Color, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String text, Color color) {
    return PopupMenuItem(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(double left, String url) {
    return Positioned(
      left: left,
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: kCardColor, width: 2),
          color: Colors.grey.shade800,
        ),
        child: ClipOval(
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 14, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}
