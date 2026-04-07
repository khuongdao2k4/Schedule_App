import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_model.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔥 Thêm task
  Future<void> addTask(Task task) async {
    await _db.collection('tasks').add(task.toMap());
  }

  // 🔥 Cập nhật toàn bộ task (Sửa title/description/dueDate)
  Future<void> updateTask(Task task) async {
    if (task.id == null) return;
    await _db.collection('tasks').doc(task.id).update(task.toMap());
  }

  // 🔥 Lấy danh sách task (Sắp xếp thông minh)
  Stream<List<Task>> getTasks(String userId) {
    return _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => Task.fromMap(doc.data(), doc.id))
          .toList();

      tasks.sort((a, b) {
        if (a.isDone != b.isDone) {
          return a.isDone ? 1 : -1;
        }
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

      return tasks;
    });
  }

  // 🔥 Toggle trạng thái hoàn thành (Check/Uncheck)
  Future<void> toggleDone(Task task) async {
    if (task.id == null) return;
    await _db.collection('tasks').doc(task.id).update({
      'isDone': !task.isDone,
    });
  }

  // 🔥 Xóa task
  Future<void> deleteTask(String id) async {
    await _db.collection('tasks').doc(id).delete();
  }
}