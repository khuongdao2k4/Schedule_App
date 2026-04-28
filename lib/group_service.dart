import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'group_model.dart';
import 'task_model.dart';

class GroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createGroup(String name, String ownerId) async {
    final docRef = await _db.collection('groups').add({
      'name': name,
      'ownerId': ownerId,
      'members': [ownerId],
      'invitedMembers': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Stream<List<Group>> getGroups(String userId) {
    final memberGroupsStream = _db
        .collection('groups')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Group.fromMap(doc.data(), doc.id))
            .toList());

    final invitedGroupsStream = _db
        .collection('groups')
        .where('invitedMembers', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Group.fromMap(doc.data(), doc.id))
            .toList());

    return rx.CombineLatestStream.combine2<List<Group>, List<Group>, List<Group>>(
      memberGroupsStream,
      invitedGroupsStream,
      (memberGroups, invitedGroups) {
        final Map<String, Group> allGroups = {};
        for (var g in memberGroups) {
          allGroups[g.id] = g;
        }
        for (var g in invitedGroups) {
          allGroups[g.id] = g;
        }
        
        final list = allGroups.values.toList();
        list.sort((a, b) {
          DateTime timeA = a.lastMessageTime ?? a.createdAt;
          DateTime timeB = b.lastMessageTime ?? b.createdAt;
          return timeB.compareTo(timeA);
        });
        return list;
      },
    );
  }

  Future<void> inviteMember(String groupId, String email) async {
    final userSnapshot = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userSnapshot.docs.isEmpty) {
      throw Exception('User not found');
    }

    final userId = userSnapshot.docs.first.id;
    final groupDoc = await _db.collection('groups').doc(groupId).get();
    final List members = groupDoc.data()?['members'] ?? [];
    if (members.contains(userId)) {
      throw Exception('Người dùng đã là thành viên');
    }

    await _db.collection('groups').doc(groupId).update({
      'invitedMembers': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> acceptInvitation(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([userId]),
      'invitedMembers': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> declineInvitation(String groupId, String userId) async {
    await _db.collection('groups').doc(groupId).update({
      'invitedMembers': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> addMember(String groupId, String email) => inviteMember(groupId, email);

  Stream<List<Task>> getGroupTasks(String groupId) {
    return _db
        .collection('tasks')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((snapshot) {
          final tasks = snapshot.docs
            .map((doc) => Task.fromMap(doc.data(), doc.id))
            .toList();
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
    
    await _db.collection('groups').doc(groupId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
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

    return rx.CombineLatestStream.combine2<List<Task>, List<Map<String, dynamic>>, List<dynamic>>(
      tasksStream,
      messagesStream,
      (tasks, messages) {
        List<dynamic> combined = [...tasks, ...messages];
        combined.sort((a, b) {
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
    final taskDoc = await _db.collection('tasks').doc(taskId).get();
    if (!taskDoc.exists) return;

    final task = Task.fromMap(taskDoc.data()!, taskDoc.id);
    
    // Logic mới: Nếu task có endTime và hiện tại đã quá hạn thì không cho duyệt
    if (task.endTime != null && DateTime.now().isAfter(task.endTime!)) {
      throw Exception('Nhiệm vụ này đã hết hạn, không thể duyệt nữa!');
    }

    await _db.collection('tasks').doc(taskId).update({'status': 'approved'});
  }

  Future<void> declineTask(String taskId) async {
    await _db.collection('tasks').doc(taskId).update({'status': 'declined'});
  }
}
