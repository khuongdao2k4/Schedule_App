import 'package:cloud_firestore/cloud_firestore.dart';
import 'group_model.dart';
import 'task_model.dart';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new group
  Future<String> createGroup(String name, String ownerId) async {
    final docRef = await _db.collection('groups').add({
      'name': name,
      'ownerId': ownerId,
      'members': [ownerId],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // Get list of groups for a user
  Stream<List<Group>> getGroups(String userId) {
    return _db
        .collection('groups')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Group.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Add member to group by email
  Future<void> addMember(String groupId, String email) async {
    final userSnapshot = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userSnapshot.docs.isEmpty) {
      throw Exception('User not found');
    }

    final userId = userSnapshot.docs.first.id;
    await _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  // Get tasks for a group (Bỏ tạm orderBy để tránh lỗi Index)
  Stream<List<Task>> getGroupTasks(String groupId) {
    return _db
        .collection('tasks')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
            .map((doc) => Task.fromMap(doc.data(), doc.id))
            .toList();
          
          // Sắp xếp phía Client để không cần Index
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tasks;
        });
  }

  // Approve a task
  Future<void> approveTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': 'approved',
    });
  }

  // Decline a task
  Future<void> declineTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({
      'status': 'declined',
    });
  }
}
