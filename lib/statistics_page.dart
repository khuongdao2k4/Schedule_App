import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'task_model.dart';
import 'task_service.dart';

const kBackgroundColor = Color(0xFF0F172A);
const kCardColor = Color(0xFF1E293B);
const kAccentColor = Color(0xFF38BDF8);
const kSuccessColor = Color(0xFF4ADE80);
const kWarningColor = Color(0xFFFBBF24);
const kErrorColor = Color(0xFFF87171);
const kTextPrimary = Colors.white;
const kTextSecondary = Color(0xFF94A3B8);

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> with SingleTickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  String _timeRange = 'Tuần';

  final Map<String, String> _categoryTranslation = {
    'Work': 'Công việc',
    'Study': 'Học tập',
    'Personal': 'Cá nhân',
    'Health': 'Sức khỏe',
    'Entertainment': 'Vui chơi',
    'Self-Improvement': 'Rèn luyện',
    'Finance': 'Tài chính',
    'Other': 'Khác',
  };

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Phân tích Năng suất",
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Task>>(
        stream: _taskService.getTasks(user?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kAccentColor));
          }

          final allTasks = snapshot.data ?? [];
          final filteredTasks = _getStandardizedFilteredTasks(allTasks, _timeRange);
          
          return _buildBody(filteredTasks, allTasks);
        },
      ),
    );
  }

  List<Task> _getStandardizedFilteredTasks(List<Task> tasks, String range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (range == 'Ngày') {
      return tasks.where((t) {
        final d = t.dueDate ?? t.createdAt;
        return d.year == today.year && d.month == today.month && d.day == today.day;
      }).toList();
    } else if (range == 'Tuần') {
      int weekDay = now.weekday;
      final startOfWeek = today.subtract(Duration(days: weekDay - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
      
      return tasks.where((t) {
        final d = t.dueDate ?? t.createdAt;
        return d.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && d.isBefore(endOfWeek);
      }).toList();
    } else if (range == 'Tháng') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      
      return tasks.where((t) {
        final d = t.dueDate ?? t.createdAt;
        return d.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) && d.isBefore(endOfMonth);
      }).toList();
    }
    return tasks;
  }

  Widget _buildBody(List<Task> filteredTasks, List<Task> allTasks) {
    final now = DateTime.now();
    final completed = filteredTasks.where((t) => t.isDone).toList();
    final overdueInPeriod = filteredTasks.where((t) => !t.isDone && t.dueDate != null && t.dueDate!.isBefore(now)).toList();
    
    int streak = _calculateStreak(allTasks.where((t) => t.isDone).toList());
    int score = _calculateProductivityScore(filteredTasks);
    double rate = filteredTasks.isEmpty ? 0 : completed.length / filteredTasks.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeRangeSelector(),
          const SizedBox(height: 25),
          _buildProductivityCard(score, rate, filteredTasks),
          const SizedBox(height: 20),
          _buildSummaryGrid(filteredTasks.length, completed.length, overdueInPeriod.length, streak),
          const SizedBox(height: 30),
          
          _buildBalanceAnalysis(filteredTasks),
          const SizedBox(height: 30),

          _buildSectionHeader("Hoạt động trong $_timeRange hiện tại", Icons.auto_graph_rounded),
          const SizedBox(height: 15),
          _buildMainChart(allTasks, _timeRange),
          const SizedBox(height: 30),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCategoryBreakdown(filteredTasks)),
              const SizedBox(width: 15),
              Expanded(child: _buildPriorityBreakdown(filteredTasks)),
            ],
          ),
          const SizedBox(height: 30),
          _buildTimeAnalysis(filteredTasks),
          const SizedBox(height: 20),
          _buildOverdueStatus(overdueInPeriod.length, filteredTasks.length),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: ['Ngày', 'Tuần', 'Tháng'].map((range) {
          bool isSelected = _timeRange == range;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _timeRange = range),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? kAccentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(range, style: TextStyle(color: isSelected ? Colors.black : kTextSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductivityCard(int score, double rate, List<Task> tasks) {
    String advice = _getLifeBalanceAdvice(tasks);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kAccentColor, const Color(0xFF0EA5E9)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: kAccentColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Điểm năng suất", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text("$score", style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold)),
                ],
              ),
              _buildProgressRing(rate),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text(advice, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500))),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _getLifeBalanceAdvice(List<Task> tasks) {
    if (tasks.isEmpty) return "Bắt đầu thêm công việc để tôi có thể phân tích giúp bạn!";
    
    int selfImp = tasks.where((t) => ['Self-Improvement', 'Study', 'Health'].contains(t.category)).length;
    int ent = tasks.where((t) => ['Entertainment'].contains(t.category)).length;
    double total = tasks.length.toDouble();

    if (total > 0 && selfImp / total > 0.4) {
      return "Bạn đang rèn luyện bản thân rất tích cực, nhưng hãy nhớ dành thời gian nghỉ ngơi và vui chơi nhé! 🌿";
    }
    if (total > 0 && ent / total > 0.4) {
      return "Bạn đang ưu tiên việc vui chơi quá nhiều, hãy thử bắt tay vào các công việc rèn luyện bản thân nào! 💪";
    }
    
    return "Tuyệt vời! Bạn đang duy trì sự cân bằng rất tốt giữa các hoạt động.";
  }

  Widget _buildBalanceAnalysis(List<Task> tasks) {
    int selfImp = tasks.where((t) => ['Self-Improvement', 'Study', 'Health'].contains(t.category)).length;
    int ent = tasks.where((t) => ['Entertainment'].contains(t.category)).length;
    int other = tasks.length - selfImp - ent;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Cân bằng trong $_timeRange này", Icons.balance_rounded),
          const SizedBox(height: 20),
          _buildBalanceBar("Rèn luyện", selfImp, tasks.length, Colors.tealAccent),
          const SizedBox(height: 12),
          _buildBalanceBar("Vui chơi", ent, tasks.length, Colors.orangeAccent),
          const SizedBox(height: 12),
          _buildBalanceBar("Hoạt động khác", other, tasks.length, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildBalanceBar(String label, int count, int total, Color col) {
    double percent = total == 0 ? 0 : count / total;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
            Text("${(percent * 100).toInt()}% ($count)", style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(col),
          ),
        )
      ],
    );
  }

  Widget _buildProgressRing(double rate) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(width: 85, height: 85, child: CircularProgressIndicator(value: rate, strokeWidth: 10, backgroundColor: Colors.white.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), strokeCap: StrokeCap.round)),
        Text("${(rate * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _buildSummaryGrid(int total, int completed, int overdue, int streak) {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 1.6,
      children: [
        _buildMiniCard("Đã xong", "$completed/$total", Icons.done_all, kSuccessColor),
        _buildMiniCard("Tổng Quá hạn", "$overdue", Icons.history, kErrorColor),
        _buildMiniCard("Đang làm", "${(total - completed).clamp(0, total)}", Icons.pending, kWarningColor),
        _buildMiniCard("Chuỗi ngày", "$streak d", Icons.local_fire_department, Colors.orange),
      ],
    );
  }

  Widget _buildMiniCard(String title, String val, IconData icon, Color col) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: col, size: 24), Text(title, style: const TextStyle(color: kTextSecondary, fontSize: 12))]),
          Text(val, style: const TextStyle(color: kTextPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMainChart(List<Task> allTasks, String range) {
    if (range == 'Ngày') return _buildHourlyChart(allTasks);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int daysCount;
    DateTime startDate;

    if (range == 'Tuần') {
      daysCount = 7;
      startDate = today.subtract(Duration(days: now.weekday - 1));
    } else {
      daysCount = DateTime(now.year, now.month + 1, 0).day;
      startDate = DateTime(now.year, now.month, 1);
    }

    final List<DateTime> dates = List.generate(daysCount, (i) => startDate.add(Duration(days: i)));

    return Container(
      height: 220, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end,
        children: dates.map((date) {
          final dayTasks = allTasks.where((t) => _isSameDay(t.dueDate ?? t.createdAt, date)).toList();
          final doneCount = dayTasks.where((t) => t.isDone).length;
          double hFactor = (dayTasks.length / 8).clamp(0.05, 1.0);
          double dFactor = dayTasks.isEmpty ? 0 : doneCount / dayTasks.length;

          bool isFuture = date.isAfter(today);

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Cột chứa con số bên trên
              if (dayTasks.isNotEmpty)
                Text("${dayTasks.length}", style: const TextStyle(color: kTextSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                width: range == 'Tháng' ? 6 : 12, height: 120 * hFactor,
                decoration: BoxDecoration(color: isFuture ? Colors.white10 : kAccentColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity, height: 120 * hFactor * dFactor,
                  decoration: BoxDecoration(color: kAccentColor, borderRadius: BorderRadius.circular(4), boxShadow: [BoxShadow(color: kAccentColor.withOpacity(0.3), blurRadius: 4)]),
                ),
              ),
              const SizedBox(height: 8),
              if (range == 'Tuần') Text(DateFormat('E').format(date)[0], style: TextStyle(color: _isSameDay(date, today) ? kAccentColor : kTextSecondary, fontSize: 11, fontWeight: _isSameDay(date, today) ? FontWeight.bold : FontWeight.normal)),
              if (range == 'Tháng' && date.day % 7 == 0) Text("${date.day}", style: const TextStyle(color: kTextSecondary, fontSize: 9)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHourlyChart(List<Task> allTasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayTasks = allTasks.where((t) => _isSameDay(t.dueDate ?? t.createdAt, today)).toList();

    List<String> labels = ["Sáng sớm", "Sáng", "Chiều", "Tối"];
    List<int> counts = [0, 0, 0, 0];
    for (var t in todayTasks) {
      int h = t.startTime?.hour ?? t.createdAt.hour;
      if (h < 6) counts[0]++;
      else if (h < 12) counts[1]++;
      else if (h < 18) counts[2]++;
      else counts[3]++;
    }

    return Container(
      height: 220, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (i) {
          double h = (counts[i] / 5).clamp(0.1, 1.0);
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Hiển thị con số bên trên cột
              if (counts[i] > 0)
                Text("${counts[i]}", style: const TextStyle(color: kAccentColor, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              Container(
                width: 40, height: 120 * h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [kAccentColor, kAccentColor.withOpacity(0.5)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              Text(labels[i], style: const TextStyle(color: kTextSecondary, fontSize: 11)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCategoryBreakdown(List<Task> tasks) {
    Map<String, int> map = {};
    for (var t in tasks) map[t.category] = (map[t.category] ?? 0) + 1;
    var sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Hạng mục", style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 15),
          ...sorted.take(4).map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Text(_categoryTranslation[e.key] ?? e.key, style: const TextStyle(color: kTextSecondary, fontSize: 10), overflow: TextOverflow.ellipsis)),
                  Text("${e.value}", style: const TextStyle(color: kTextPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 5),
                LinearProgressIndicator(value: tasks.isEmpty ? 0 : e.value / tasks.length, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(_getCatColor(e.key)), minHeight: 3),
              ],
            ),
          )).toList(),
          if (map.isEmpty) const Text("Trống", style: TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPriorityBreakdown(List<Task> tasks) {
    int h = tasks.where((t) => t.priority == 'High').length;
    int m = tasks.where((t) => t.priority == 'Medium').length;
    int l = tasks.where((t) => t.priority == 'Low').length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Mức ưu tiên", style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 15),
          _priorityLine("Quan trọng", h, Colors.redAccent),
          _priorityLine("Trung bình", m, Colors.orangeAccent),
          _priorityLine("Thấp", l, Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _priorityLine(String label, int count, Color col) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 11))),
          Text("$count", style: const TextStyle(color: kTextPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTimeAnalysis(List<Task> tasks) {
    int est = 0, act = 0;
    for (var t in tasks) { est += t.estimatedMinutes; act += t.actualMinutes; }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          _buildSectionHeader("Quản lý thời gian", Icons.timer_sharp),
          const SizedBox(height: 20),
          Row(
            children: [
              _timeItem("Thực tế", "${(act / 60).toStringAsFixed(1)}h", kAccentColor),
              Container(width: 1, height: 40, color: Colors.white10),
              _timeItem("Ước tính", "${(est / 60).toStringAsFixed(1)}h", kSuccessColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeItem(String label, String val, Color col) {
    return Expanded(child: Column(children: [Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 12)), const SizedBox(height: 8), Text(val, style: TextStyle(color: col, fontSize: 24, fontWeight: FontWeight.bold))]));
  }

  Widget _buildOverdueStatus(int overdueCount, int totalInPeriod) {
    double r = totalInPeriod == 0 ? 0 : overdueCount / totalInPeriod;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kErrorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: kErrorColor.withOpacity(0.1))),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: kErrorColor, size: 30),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Tỷ lệ trễ hạn trong kỳ", style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold)), Text("${(r * 100).toInt()}% công việc bị quá hạn", style: const TextStyle(color: kTextSecondary, fontSize: 13))])),
          Text("$overdueCount", style: const TextStyle(color: kErrorColor, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(children: [Icon(icon, color: kAccentColor, size: 20), const SizedBox(width: 10), Text(title, style: const TextStyle(color: kTextPrimary, fontSize: 16, fontWeight: FontWeight.bold))]);
  }

  bool _isSameDay(DateTime d1, DateTime d2) => d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  int _calculateStreak(List<Task> done) {
    if (done.isEmpty) return 0;
    Set<String> days = done.map((t) => DateFormat('yyyy-MM-dd').format(t.dueDate ?? t.createdAt)).toSet();
    int s = 0; DateTime d = DateTime.now();
    if (!days.contains(DateFormat('yyyy-MM-dd').format(d))) d = d.subtract(const Duration(days: 1));
    while (days.contains(DateFormat('yyyy-MM-dd').format(d))) { s++; d = d.subtract(const Duration(days: 1)); }
    return s;
  }

  int _calculateProductivityScore(List<Task> tasks) {
    if (tasks.isEmpty) return 0;
    double tot = 0, comp = 0;
    for (var t in tasks) {
      double w = t.priority == 'High' ? 3 : (t.priority == 'Medium' ? 2 : 1);
      tot += w; if (t.isDone) comp += w;
    }
    return (comp / tot * 100).toInt();
  }

  Color _getCatColor(String c) {
    switch (c) {
      case 'Work': return const Color(0xFF6366F1);
      case 'Study': return const Color(0xFFEC4899);
      case 'Personal': return const Color(0xFF10B981);
      case 'Health': return const Color(0xFFF59E0B);
      case 'Entertainment': return Colors.orangeAccent;
      case 'Self-Improvement': return Colors.tealAccent;
      default: return kAccentColor;
    }
  }
}
