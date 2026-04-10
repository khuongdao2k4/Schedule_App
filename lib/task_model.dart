import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String? id;
  String userId;
  String title;
  String description;
  DateTime createdAt;
  DateTime? startTime;
  DateTime? endTime;
  DateTime? dueDate;
  bool isDone;
  int? iconCode;
  
  // Các trường mới để phục vụ thống kê chuyên sâu
  String priority; // Low, Medium, High
  String category; // Work, Study, Personal, Health, etc.
  int estimatedMinutes;
  int actualMinutes;
  int rescheduleCount;

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
    this.priority = 'Medium',
    this.category = 'Personal',
    this.estimatedMinutes = 30,
    this.actualMinutes = 0,
    this.rescheduleCount = 0,
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
      'priority': priority,
      'category': category,
      'estimatedMinutes': estimatedMinutes,
      'actualMinutes': actualMinutes,
      'rescheduleCount': rescheduleCount,
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
      priority: map['priority'] ?? 'Medium',
      category: map['category'] ?? 'Personal',
      estimatedMinutes: map['estimatedMinutes'] ?? 30,
      actualMinutes: map['actualMinutes'] ?? 0,
      rescheduleCount: map['rescheduleCount'] ?? 0,
    );
  }
}
