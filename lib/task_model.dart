import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String? id;
  String userId;
  String title;
  String description;
  DateTime createdAt;
  DateTime? dueDate; // 🔥 Hạn hoàn thành
  bool isDone;

  Task({
    this.id,
    required this.userId,
    required this.title,
    this.description = '',
    DateTime? createdAt,
    this.dueDate,
    this.isDone = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isDone': isDone,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      dueDate: map['dueDate'] != null ? (map['dueDate'] as Timestamp).toDate() : null,
      isDone: map['isDone'] ?? false,
    );
  }
}