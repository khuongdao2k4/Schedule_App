import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'auth_service.dart';
import 'user_service.dart';
import 'task_model.dart';
import 'task_service.dart';

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
// ================= CLIPPER ====================
//////////////////////////////////////////////////
class PriorityCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double bevel = 35.0;
    double radius = 25.0;
    Path path = Path();
    
    // Start after bevel
    path.moveTo(bevel, 0);
    
    // Top right corner
    path.lineTo(size.width - radius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, radius);
    
    // Bottom right corner
    path.lineTo(size.width, size.height - radius);
    path.quadraticBezierTo(size.width, size.height, size.width - radius, size.height);
    
    // Bottom left corner
    path.lineTo(radius, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - radius);
    
    // Bevel point
    path.lineTo(0, bevel);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

//////////////////////////////////////////////////
// ================= LOGIN PAGE =================
//////////////////////////////////////////////////
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPriority1Color,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
          onPressed: () async {
            final user = await AuthService().signInWithGoogle();
            if (user != null) {
              await UserService().saveUser(user);
              if (!context.mounted) return;
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => const HomePage()));
            }
          },
          child: const Text("Login with Google",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime? _selectedDate;

  void _showAddDialog() {
    _titleController.clear();
    _descController.clear();
    _selectedDate = null;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: kCardColor,
          title: const Text("New Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Task Title")),
              TextField(controller: _descController, decoration: const InputDecoration(labelText: "Project/Description")),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(_selectedDate == null ? "No Deadline" : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: kPriority2Color),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setDialogState(() => _selectedDate = picked);
                    },
                  )
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (_titleController.text.isNotEmpty && user != null) {
                  final task = Task(
                    title: _titleController.text,
                    description: _descController.text,
                    userId: user.uid,
                    isDone: false,
                    createdAt: DateTime.now(),
                    dueDate: _selectedDate,
                  );
                  await _taskService.addTask(task);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
              },
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Task task) {
    final editTitle = TextEditingController(text: task.title);
    final editDesc = TextEditingController(text: task.description);
    DateTime? tempDate = task.dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: kCardColor,
          title: const Text("Edit Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: editTitle, decoration: const InputDecoration(labelText: "Title")),
              TextField(controller: editDesc, decoration: const InputDecoration(labelText: "Description")),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(tempDate == null ? "No Deadline" : DateFormat('dd/MM/yyyy').format(tempDate!)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.calendar_today, color: kPriority2Color),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setDialogState(() => tempDate = picked);
                    },
                  )
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (editTitle.text.isNotEmpty) {
                  final updatedTask = Task(
                    id: task.id,
                    userId: task.userId,
                    title: editTitle.text,
                    description: editDesc.text,
                    createdAt: task.createdAt,
                    dueDate: tempDate,
                    isDone: task.isDone,
                  );
                  await _taskService.updateTask(updatedTask);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
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
            final tasks = snapshot.data ?? [];
            final todoCount = tasks.where((t) => !t.isDone).length;
            final doneCount = tasks.where((t) => t.isDone).length;

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
                  // --- Thẻ Priority (Giữ cố định) ---
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
                            _buildPriorityCard("Tổng cộng", "${tasks.length} task", kPriority3Color, 105, Icons.apps),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),
                  const Text("On Going Task", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // --- Phần danh sách Task (Chỉ phần này lướt) ---
                  Expanded(
                    child: tasks.isEmpty
                      ? const Center(child: Text("No tasks found"))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 120), // Tránh đè lên navbar
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return Dismissible(
                              key: Key(task.id ?? index.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (_) => _taskService.deleteTask(task.id!),
                              child: _buildTaskItem(task),
                            );
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
            IconButton(icon: const Icon(Icons.fact_check_outlined, color: Colors.grey, size: 28), onPressed: () {}),
            GestureDetector(
              onTap: _showAddDialog,
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

  Widget _buildPriorityCard(String title, String count, Color color, double height, IconData icon, {bool isLarge = false}) {
    Widget iconBox = Transform.rotate(
      angle: 0.785,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kBackgroundColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Transform.rotate(
          angle: -0.785,
          child: Icon(icon, color: color, size: 24),
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
                iconBox,
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
    return GestureDetector(
      onTap: () => _showEditDialog(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _taskService.toggleDone(task),
                  child: Transform.rotate(
                    angle: 0.785,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: task.isDone ? kPriority1Color : kBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Transform.rotate(
                        angle: -0.785,
                        child: Icon(task.isDone ? Icons.check : Icons.grid_view_rounded, 
                             color: task.isDone ? Colors.black : kPriority2Color, size: 22),
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
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                        color: task.isDone ? Colors.grey : Colors.white,
                      )),
                      Text(task.description.isEmpty ? "Client project" : task.description, 
                           style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.more_vert, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const SizedBox(width: 45),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: task.isDone ? 1.0 : 0.0,
                      backgroundColor: kBackgroundColor,
                      valueColor: AlwaysStoppedAnimation<Color>(task.isDone ? kPriority1Color : kPriority2Color),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(task.isDone ? "100%" : "0%", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
