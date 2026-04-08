import 'package:cloud_firestore/cloud_firestore.dart';
import 'task_model.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔥 Kiểm tra trùng thời gian (Overlap)
  Future<bool> isTimeOverlapping(String userId, DateTime start, DateTime end, {String? excludeId}) async {
    final query = await _db
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in query.docs) {
      if (excludeId != null && doc.id == excludeId) continue;
      
      final data = doc.data();
      if (data['startTime'] == null || data['endTime'] == null) continue;

      final existingStart = (data['startTime'] as Timestamp).toDate();
      final existingEnd = (data['endTime'] as Timestamp).toDate();

      // Logic kiểm tra chồng lấn:
      // (Bắt đầu 1 < Kết thúc 2) VÀ (Kết thúc 1 > Bắt đầu 2)
      if (start.isBefore(existingEnd) && end.isAfter(existingStart)) {
        return true;
      }
    }
    return false;
  }

  // 🔥 Thêm task (có kiểm tra trùng)
  Future<void> addTask(Task task) async {
    await _db.collection('tasks').add(task.toMap());
  }

  // 🔥 Cập nhật toàn bộ task
  Future<void> updateTask(Task task) async {
    if (task.id == null) return;
    await _db.collection('tasks').doc(task.id).update(task.toMap());
  }

  // 🔥 Lấy danh sách task
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
        if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });

      return tasks;
    });
  }

  // 🔥 Toggle trạng thái hoàn thành
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