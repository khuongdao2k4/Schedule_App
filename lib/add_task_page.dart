import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task_service.dart';
import 'task_model.dart';
import 'package:intl/intl.dart';

const kBackgroundColor = Color(0xFF1B2333); 
const kCardColor = Color(0xFF263042); 
const kPriority1Color = Color(0xFFC9E8A2); 
const kPriority2Color = Color(0xFF4ED9F5); 
const kPriority3Color = Color(0xFFCDC1D8); 

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  DateTime? selectedDay;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  
  final taskService = TaskService();
  IconData selectedIcon = Icons.assignment_outlined;

  final List<IconData> taskIcons = [
    Icons.fitness_center,
    Icons.book,
    Icons.directions_run,
    Icons.bed,
    Icons.work,
    Icons.restaurant,
    Icons.code,
    Icons.movie,
    Icons.shopping_cart,
    Icons.assignment_outlined,
  ];

  void saveTask() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || titleController.text.isEmpty || selectedDay == null || startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin và thời gian!")));
      return;
    }

    final startDateTime = DateTime(selectedDay!.year, selectedDay!.month, selectedDay!.day, startTime!.hour, startTime!.minute);
    final endDateTime = DateTime(selectedDay!.year, selectedDay!.month, selectedDay!.day, endTime!.hour, endTime!.minute);

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thời gian kết thúc phải sau thời gian bắt đầu!")));
      return;
    }

    // 🔥 Kiểm tra trùng lịch
    final isOverlapping = await taskService.isTimeOverlapping(user.uid, startDateTime, endDateTime);
    if (isOverlapping) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Thời gian này đã có task khác, vui lòng chọn khung giờ khác!"),
          backgroundColor: Colors.redAccent,
        )
      );
      return;
    }

    final task = Task(
      userId: user.uid,
      title: titleController.text,
      description: descController.text,
      createdAt: DateTime.now(),
      startTime: startDateTime,
      endTime: endDateTime,
      dueDate: selectedDay,
      isDone: false,
      iconCode: selectedIcon.codePoint,
    );

    await taskService.addTask(task);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text("Create New Task", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Task Title"),
            _buildTextField(titleController, "Enter task name..."),
            const SizedBox(height: 25),
            
            _buildLabel("Project/Description"),
            _buildTextField(descController, "What needs to be done?", maxLines: 3),
            const SizedBox(height: 25),

            _buildLabel("Select Icon"),
            SizedBox(
              height: 55,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: taskIcons.length,
                itemBuilder: (context, index) {
                  bool isSelected = selectedIcon == taskIcons[index];
                  return GestureDetector(
                    onTap: () => setState(() => selectedIcon = taskIcons[index]),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 55,
                      decoration: BoxDecoration(
                        color: isSelected ? kPriority1Color : kCardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? kPriority1Color : Colors.white10),
                      ),
                      child: Icon(
                        taskIcons[index],
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 25),

            _buildLabel("Select Date"),
            _buildPickerTile(
              icon: Icons.calendar_today,
              text: selectedDay == null ? "Choose a date" : DateFormat('dd MMMM, yyyy').format(selectedDay!),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => selectedDay = picked);
              },
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Start Time"),
                      _buildPickerTile(
                        icon: Icons.access_time,
                        text: startTime == null ? "Start" : startTime!.format(context),
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (picked != null) setState(() => startTime = picked);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("End Time"),
                      _buildPickerTile(
                        icon: Icons.access_time,
                        text: endTime == null ? "End" : endTime!.format(context),
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (picked != null) setState(() => endTime = picked);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 50),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPriority1Color,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                      bottomLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "CREATE TASK",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildPickerTile({required IconData icon, required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: kPriority2Color, size: 20),
            const SizedBox(width: 15),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}