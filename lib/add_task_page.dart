import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task_service.dart';
import 'task_model.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final titleController = TextEditingController();
  final descController = TextEditingController();

  final taskService = TaskService();

  void saveTask() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (titleController.text.isEmpty) return;

    final task = Task(
      userId: user.uid,
      title: titleController.text,
      description: descController.text,
      createdAt: DateTime.now(),
      isDone: false,
    );

    await taskService.addTask(task);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thêm Task")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Tiêu đề"),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Mô tả"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveTask,
              child: const Text("Lưu"),
            )
          ],
        ),
      ),
    );
  }
}