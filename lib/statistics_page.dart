import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'task_model.dart';
import 'task_service.dart';

const kBackgroundColor = Color(0xFF1B2333);
const kCardColor = Color(0xFF263042);
const kPriority1Color = Color(0xFFC9E8A2);
const kPriority2Color = Color(0xFF4ED9F5);
const kPriority3Color = Color(0xFFCDC1D8);

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final TaskService _taskService = TaskService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Thống kê chi tiết", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Task>>(
        stream: _taskService.getTasks(user?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPriority2Color));
          }

          final allTasks = snapshot.data ?? [];
          final now = DateTime.now();

          // 1. Overview data
          final totalTasks = allTasks.length;
          final completedTasks = allTasks.where((t) => t.isDone).length;
          final expiredTasks = allTasks.where((t) => !t.isDone && t.endTime != null && now.isAfter(t.endTime!)).length;
          final pendingTasks = totalTasks - completedTasks - expiredTasks;
          final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;
          
          // Điểm năng suất (Tạm tính: mỗi task xong được 10 điểm)
          final productivityScore = completedTasks * 10;

          // 2. Streaks (Chuỗi ngày liên tiếp)
          final streaks = _calculateStreaks(allTasks);

          // 3. Time-based data (7 ngày qua)
          final last7Days = List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. OVERVIEW ---
                const Text("TỔNG QUAN NĂNG SUẤT", style: TextStyle(fontSize: 14, letterSpacing: 1.2, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildProductivityHeader(completionRate, productivityScore, streaks),
                const SizedBox(height: 20),
                _buildOverviewGrid(totalTasks, completedTasks, pendingTasks, expiredTasks),

                const SizedBox(height: 35),
                // --- 2. THỜI GIAN ---
                const Text("PHÂN TÍCH THỜI GIAN", style: TextStyle(fontSize: 14, letterSpacing: 1.2, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildWeeklyComparisonChart(allTasks, last7Days),
                const SizedBox(height: 20),
                const Text("Khung giờ hiệu quả nhất", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildHourlyHeatmap(allTasks),

                const SizedBox(height: 35),
                // --- 3. PHÂN LOẠI ---
                const Text("PHÂN LOẠI & ƯU TIÊN", style: TextStyle(fontSize: 14, letterSpacing: 1.2, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildCategoryDonutChart(allTasks),

                const SizedBox(height: 35),
                // --- 5. QUÁ HẠN ---
                const Text("PHÂN TÍCH TRÌ HOÃN", style: TextStyle(fontSize: 14, letterSpacing: 1.2, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildOverdueAnalysis(totalTasks, expiredTasks),

                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildProductivityHeader(double rate, int score, int streaks) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2E89C3), Color(0xFF0D304B)]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildHeaderStat("Tỷ lệ", "${(rate * 100).toInt()}%"),
          _buildHeaderStat("Điểm", score.toString()),
          _buildHeaderStat("Chuỗi ngày liên tiếp", "$streaks ngày"),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
      ],
    );
  }

  Widget _buildOverviewGrid(int total, int done, int pending, int expired) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _buildMiniCard("Tổng nhiệm vụ", total.toString(), kPriority2Color),
        _buildMiniCard("Đã hoàn thành", done.toString(), kPriority1Color),
        _buildMiniCard("Đang thực hiện", pending.toString(), kPriority3Color),
        _buildMiniCard("Đã quá hạn", expired.toString(), Colors.redAccent),
      ],
    );
  }

  Widget _buildMiniCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildWeeklyComparisonChart(List<Task> tasks, List<DateTime> days) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(25)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((day) {
          final created = tasks.where((t) => isSameDay(t.createdAt, day)).length;
          final done = tasks.where((t) => t.isDone && t.dueDate != null && isSameDay(t.dueDate!, day)).length;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar(created.toDouble(), kPriority2Color.withOpacity(0.5)),
                  const SizedBox(width: 4),
                  _buildBar(done.toDouble(), kPriority1Color),
                ],
              ),
              const SizedBox(height: 8),
              Text(DateFormat('E').format(day)[0], style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBar(double value, Color color) {
    return Container(
      width: 8,
      height: (value * 15).clamp(4, 100),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
    );
  }

  Widget _buildHourlyHeatmap(List<Task> tasks) {
    // Giả lập biểu đồ nhiệt theo khung giờ
    final doneTasks = tasks.where((t) => t.isDone && t.endTime != null).toList();
    List<int> hourlyCounts = List.filled(6, 0); // Chia làm 6 block: 0-4h, 4-8h, ..., 20-24h

    for (var t in doneTasks) {
      int hour = t.endTime!.hour;
      hourlyCounts[hour ~/ 4]++;
    }

    return Row(
      children: List.generate(6, (index) {
        double opacity = (hourlyCounts[index] / 5).clamp(0.1, 1.0);
        return Expanded(
          child: Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: kPriority1Color.withOpacity(opacity),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text("${index * 4}h", style: const TextStyle(fontSize: 10, color: Colors.black54))),
          ),
        );
      }),
    );
  }

  Widget _buildCategoryDonutChart(List<Task> tasks) {
    final Map<String, int> categories = {};
    for (var task in tasks) {
      String cat = _getCategoryName(task.title);
      categories[cat] = (categories[cat] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: categories.entries.map((e) {
          double percent = tasks.isEmpty ? 0 : e.value / tasks.length;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _getCategoryIcon(e.key),
                const SizedBox(width: 15),
                Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white))),
                SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: kBackgroundColor,
                    color: kPriority2Color,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(width: 10),
                Text("${(percent * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverdueAnalysis(int total, int expired) {
    double overdueRate = total == 0 ? 0 : expired / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${(overdueRate * 100).toInt()}% nhiệm vụ bị trễ hạn", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text("Hãy cân nhắc giảm khối lượng công việc hoặc chia nhỏ các task để quản lý tốt hơn.", style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  // --- LOGIC HELPER ---

  int _calculateStreaks(List<Task> tasks) {
    if (tasks.isEmpty) return 0;
    final doneDates = tasks
        .where((t) => t.isDone && t.dueDate != null)
        .map((t) => DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (doneDates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Nếu hôm nay chưa xong task nào, bắt đầu kiểm tra từ hôm qua
    if (!doneDates.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    for (var date in doneDates) {
      if (date == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (date.isBefore(checkDate)) {
        break;
      }
    }
    return streak;
  }

  bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _getCategoryName(String title) {
    final t = title.toLowerCase();
    if (t.contains('học') || t.contains('bài')) return 'Học tập';
    if (t.contains('làm') || t.contains('work')) return 'Công việc';
    if (t.contains('gym') || t.contains('tập') || t.contains('chạy')) return 'Sức khỏe';
    return 'Cá nhân';
  }

  Widget _getCategoryIcon(String name) {
    IconData icon = Icons.bookmark;
    if (name == 'Học tập') icon = Icons.book;
    if (name == 'Công việc') icon = Icons.work;
    if (name == 'Sức khỏe') icon = Icons.fitness_center;
    return Icon(icon, color: kPriority1Color, size: 20);
  }
}
