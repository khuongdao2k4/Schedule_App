import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart' as rx; // Sử dụng alias để tránh xung đột
import 'group_model.dart';
import 'task_model.dart';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createGroup(String name, String ownerId) async {
    final docRef = await _db.collection('groups').add({
      'name': name,
      'ownerId': ownerId,
      'members': [ownerId],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Stream<List<Group>> getGroups(String userId) {
    return _db
        .collection('groups')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Group.fromMap(doc.data(), doc.id))
            .toList());
  }

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

  Stream<List<Task>> getGroupTasks(String groupId) {
    return _db
        .collection('tasks')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
            .map((doc) => Task.fromMap(doc.data(), doc.id))
            .toList();
          // Sắp xếp an toàn
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return tasks;
        });
  }

  Future<void> sendChatMessage(String groupId, String senderId, String text) async {
    await _db.collection('groups').doc(groupId).collection('messages').add({
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'chat',
    });
  }

  Stream<List<dynamic>> getGroupCombinedMessages(String groupId) {
    final tasksStream = _db
        .collection('tasks')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Task.fromMap(doc.data(), doc.id)).toList());

    final messagesStream = _db
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());

    // Sử dụng alias rx.CombineLatestStream để dứt điểm lỗi "Rx isn't defined"
    return rx.CombineLatestStream.combine2<List<Task>, List<Map<String, dynamic>>, List<dynamic>>(
      tasksStream,
      messagesStream,
      (tasks, messages) {
        List<dynamic> combined = [...tasks, ...messages];
        combined.sort((a, b) {
          // Xử lý null an toàn cho timestamp
          DateTime getTime(dynamic item) {
            if (item is Task) return item.createdAt;
            if (item is Map && item.containsKey('timestamp') && item['timestamp'] != null) {
              return (item['timestamp'] as Timestamp).toDate();
            }
            return DateTime.now();
          }
          
          return getTime(b).compareTo(getTime(a));
        });
        return combined;
      },
    );
  }

  Future<void> approveTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({'status': 'approved'});
  }

  Future<void> declineTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({'status': 'declined'});
  }
}
