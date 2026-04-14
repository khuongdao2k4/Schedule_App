import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUser(User user) async {
    await _db.collection('users').doc(user.uid).set({
      'name': user.displayName,
      'email': user.email,
      'photo': user.photoURL,
      'lastLogin': DateTime.now(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final snapshot = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      data['uid'] = snapshot.docs.first.id;
      return data;
    }
    return null;
  }
}
