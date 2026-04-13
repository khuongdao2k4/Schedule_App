import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String? id;
  final String userId;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? dueDate;
  final bool isDone;
  final int? iconCode;
  final String priority;
  final String category;
  final int estimatedMinutes;
  final int actualMinutes;
  final int rescheduleCount;

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

  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? dueDate,
    bool? isDone,
    int? iconCode,
    String? priority,
    String? category,
    int? estimatedMinutes,
    int? actualMinutes,
    int? rescheduleCount,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dueDate: dueDate ?? this.dueDate,
      isDone: isDone ?? this.isDone,
      iconCode: iconCode ?? this.iconCode,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      rescheduleCount: rescheduleCount ?? this.rescheduleCount,
    );
  }

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
