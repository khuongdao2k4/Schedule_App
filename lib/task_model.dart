import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String? id;
  String userId;
  String title;
  String description;
  DateTime createdAt;
  DateTime? startTime; // Giờ bắt đầu
  DateTime? endTime;   // Giờ kết thúc
  DateTime? dueDate;   // Ngày (có thể dùng chung hoặc tách riêng)
  bool isDone;
  int? iconCode;

  Task({
    this.id,
    required this.userId,
    required this.title,
    this.description = '',
    DateTime? createdAt,
    this.startTime,
    this.endTime,
    this.dueDate,
    this.isDone = false,
    this.iconCode,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isDone': isDone,
      'iconCode': iconCode,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      startTime: map['startTime'] != null ? (map['startTime'] as Timestamp).toDate() : null,
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
      dueDate: map['dueDate'] != null ? (map['dueDate'] as Timestamp).toDate() : null,
      isDone: map['isDone'] ?? false,
      iconCode: map['iconCode'],
    );
  }
}