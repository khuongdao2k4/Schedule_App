import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task_model.dart';
import 'notification_service.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // 🔥 Kiểm tra trùng thời gian (Overlap)
  Future<bool> isTimeOverlapping(String userId, DateTime start, DateTime end, {String? excludeId}) async {
    // Kiểm tra trùng trên cả những task mình tạo HOẶC những task mình được giao
    final query = await _db
        .collection('tasks')
        .where(Filter.or(
          Filter('userId', isEqualTo: userId),
          Filter('assignees', arrayContains: userId),
        ))
        .get();

    for (var doc in query.docs) {
      if (excludeId != null && doc.id == excludeId) continue;
      
      final data = doc.data();
      if (data['startTime'] == null || data['endTime'] == null) continue;

      final existingStart = (data['startTime'] as Timestamp).toDate();
      final existingEnd = (data['endTime'] as Timestamp).toDate();

      if (start.isBefore(existingEnd) && end.isAfter(existingStart)) {
        return true;
      }
    }
    return false;
  }

  // 🔥 Thêm task
  Future<void> addTask(Task task) async {
    DocumentReference docRef = await _db.collection('tasks').add(task.toMap());
    Task newTask = task.copyWith(id: docRef.id);
    await _notificationService.scheduleTaskNotifications(newTask);
  }

  // 🔥 Cập nhật toàn bộ task
  Future<void> updateTask(Task task) async {
    if (task.id == null) return;
    await _db.collection('tasks').doc(task.id).update(task.toMap());
    await _notificationService.cancelTaskNotifications(task.id!);
    if (!task.isDone) {
      await _notificationService.scheduleTaskNotifications(task);
    }
  }

  // 🔥 Lấy danh sách task (Lấy cả task cũ và task mới)
  Stream<List<Task>> getTasks(String userId) {
    return _db
        .collection('tasks')
        .where(Filter.or(
          Filter('userId', isEqualTo: userId),
          Filter('assignees', arrayContains: userId),
        ))
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

  // 🔥 Toggle trạng thái hoàn thành cá nhân
  Future<void> toggleDone(Task task) async {
    if (task.id == null) return;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    List<String> newCompletedBy = List.from(task.completedBy);
    if (newCompletedBy.contains(currentUid)) {
      newCompletedBy.remove(currentUid);
    } else {
      newCompletedBy.add(currentUid);
    }

    bool allCompleted = newCompletedBy.length >= task.assignees.length;

    await _db.collection('tasks').doc(task.id).update({
      'completedBy': newCompletedBy,
      'isDone': allCompleted,
    });
    
    if (allCompleted) {
      await _notificationService.cancelTaskNotifications(task.id!);
    } else {
      await _notificationService.scheduleTaskNotifications(task);
    }
  }

  // 🔥 Xóa task
  Future<void> deleteTask(String id) async {
    await _db.collection('tasks').doc(id).delete();
    await _notificationService.cancelTaskNotifications(id);
  }
}
