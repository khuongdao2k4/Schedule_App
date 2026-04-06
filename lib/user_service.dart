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
}