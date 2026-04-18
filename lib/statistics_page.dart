import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'task_model.dart';
import 'task_service.dart';
import 'main.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final TaskService _taskService = TaskService();
  String _timeRange = 'Tuần';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Phân tích Năng suất",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Task>>(
        stream: _taskService.getTasks(user?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kPriority1Color));
          }

          final allTasks = snapshot.data ?? [];
          final filteredTasks = _getFilteredTasks(allTasks, _timeRange);
          
          return _buildBody(filteredTasks, allTasks);
        },
      ),
    );
  }

  List<Task> _getFilteredTasks(List<Task> tasks, String range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (range == 'Ngày') {
      return tasks.where((t) {
        final d = t.dueDate ?? t.createdAt;
        return d.year == today.year && d.month == today.month && d.day == today.day;
      }).toList();
    } else if (range == 'Tuần') {
      final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
      return tasks.where((t) {
        final d = t.dueDate ?? t.createdAt;
        return d.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && d.isBefore(endOfWeek);
      }).toList();
    } else {
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      return tasks.where((t) {
        final d = t.dueDate ?? t.createdAt;
        return d.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) && d.isBefore(endOfMonth);
      }).toList();
    }
  }

  Widget _buildBody(List<Task> filteredTasks, List<Task> allTasks) {
    final completed = filteredTasks.where((t) => t.isDone).toList();
    final overdue = filteredTasks.where((t) => !t.isDone && t.dueDate != null && t.dueDate!.isBefore(DateTime.now())).toList();
    
    int streak = _calculateStreak(allTasks.where((t) => t.isDone).toList());
    int score = _calculateScore(filteredTasks);
    double rate = filteredTasks.isEmpty ? 0 : completed.length / filteredTasks.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildTimeRangeSelector(),
          const SizedBox(height: 24),
          _buildMainProductivityCard(score, rate, filteredTasks),
          const SizedBox(height: 16),
          _buildSummaryGrid(filteredTasks.length, completed.length, overdue.length, streak),
          const SizedBox(height: 24),
          
          _buildSectionHeader("Hoạt động trong $_timeRange", Icons.bar_chart_rounded),
          const SizedBox(height: 16),
          _buildActivityChart(allTasks, _timeRange),
          const SizedBox(height: 24),

          _buildSectionHeader("Cân bằng cuộc sống", Icons.balance_rounded),
          const SizedBox(height: 16),
          _buildBalanceAnalysis(filteredTasks),
          const SizedBox(height: 24),

          _buildSectionHeader("Mức độ ưu tiên", Icons.flag_rounded),
          const SizedBox(height: 16),
          _buildPriorityAnalysis(filteredTasks),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: ['Ngày', 'Tuần', 'Tháng'].map((range) {
          bool isSelected = _timeRange == range;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _timeRange = range),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? kPriority2Color : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(range, 
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white54, 
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                  )
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainProductivityCard(int score, double rate, List<Task> tasks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kPriority2Color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: kPriority2Color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Điểm năng suất", style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("$score", style: const TextStyle(color: Colors.black, fontSize: 56, fontWeight: FontWeight.bold)),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80, height: 80,
                    child: CircularProgressIndicator(
                      value: rate,
                      strokeWidth: 8,
                      backgroundColor: Colors.black.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text("${(rate * 100).toInt()}%", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: Colors.black87, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getAdvice(tasks),
                    style: const TextStyle(color: Colors.black87, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(int total, int completed, int overdue, int streak) {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
      children: [
        _buildMiniCard("Đã xong", "$completed/$total", Icons.check_circle_outline, kPriority1Color, 
          completed == total && total > 0 ? "Hoàn hảo!" : "Cố gắng lên"),
        _buildMiniCard("Quá hạn", "$overdue", Icons.history_rounded, Colors.redAccent,
          overdue > 2 ? "Cần tập trung" : "Kiểm soát tốt"),
        _buildMiniCard("Đang làm", "${(total - completed).clamp(0, total)}", Icons.pending_outlined, kPriority2Color,
          "Chưa hoàn tất"),
        _buildMiniCard("Chuỗi ngày", "$streak ngày", Icons.local_fire_department_rounded, Colors.orangeAccent,
          streak > 3 ? "Phong độ tốt" : "Bắt đầu chuỗi"),
      ],
    );
  }

  Widget _buildMiniCard(String title, String val, IconData icon, Color color, String assessment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
            ],
          ),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(assessment, style: TextStyle(color: color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActivityChart(List<Task> allTasks, String range) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    int daysCount = range == 'Tuần' ? 7 : (range == 'Ngày' ? 24 : 30);
    DateTime startDate = range == 'Tuần' 
        ? today.subtract(Duration(days: now.weekday - 1))
        : (range == 'Ngày' ? today : DateTime(now.year, now.month, 1));

    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(daysCount, (index) {
                DateTime date = startDate.add(Duration(days: range == 'Ngày' ? 0 : index));
                if (range == 'Ngày') date = startDate.add(Duration(hours: index));

                final periodTasks = allTasks.where((t) {
                  final d = t.dueDate ?? t.createdAt;
                  if (range == 'Ngày') return d.year == date.year && d.month == date.month && d.day == date.day && d.hour == index;
                  return d.year == date.year && d.month == date.month && d.day == date.day;
                }).toList();

                double hFactor = (periodTasks.length / 5).clamp(0.05, 1.0);
                bool isDone = periodTasks.isNotEmpty && periodTasks.every((t) => t.isDone);

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 140 * hFactor,
                    decoration: BoxDecoration(
                      color: periodTasks.isEmpty 
                          ? Colors.white.withOpacity(0.05) 
                          : (isDone ? kPriority1Color : kPriority2Color.withOpacity(0.6)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            range == 'Ngày' ? "Biểu đồ theo giờ" : "Phân bổ công việc theo ngày",
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
          )
        ],
      ),
    );
  }

  Widget _buildBalanceAnalysis(List<Task> tasks) {
    int selfImp = tasks.where((t) => ['Học tập', 'Sức khỏe', 'Phát triển bản thân', 'Study', 'Health', 'Self-Improvement'].contains(t.category)).length;
    int ent = tasks.where((t) => ['Giải trí', 'Entertainment', 'Social'].contains(t.category)).length;
    
    String balanceText = "Cân bằng";
    Color balanceColor = kPriority1Color;
    if (tasks.isNotEmpty) {
      if (selfImp / tasks.length > 0.7) { balanceText = "Quá tải học tập"; balanceColor = Colors.orangeAccent; }
      else if (ent / tasks.length > 0.7) { balanceText = "Thiếu tập trung"; balanceColor = Colors.redAccent; }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Trạng thái:", style: TextStyle(color: Colors.white54, fontSize: 13)),
              Text(balanceText, style: TextStyle(color: balanceColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),
          _buildBalanceBar("Rèn luyện", selfImp, tasks.length, kPriority1Color),
          const SizedBox(height: 16),
          _buildBalanceBar("Vui chơi", ent, tasks.length, Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildBalanceBar(String label, int count, int total, Color color) {
    double percent = total == 0 ? 0 : count / total;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
            Text("${(percent * 100).toInt()}%", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.white.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        )
      ],
    );
  }

  Widget _buildPriorityAnalysis(List<Task> tasks) {
    int h = tasks.where((t) => t.priority == 'High' || t.priority == 'Cao').length;
    int m = tasks.where((t) => t.priority == 'Medium' || t.priority == 'Trung bình').length;
    
    String priorityEval = "Hợp lý";
    if (tasks.isNotEmpty && h / tasks.length > 0.5) priorityEval = "Nhiều việc gấp";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _priorityItem("Cao", h, Colors.redAccent),
              _priorityItem("Trung bình", m, Colors.orangeAccent),
              _priorityItem("Thấp", tasks.length - h - m, kPriority2Color),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Đánh giá: $priorityEval",
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontStyle: FontStyle.italic),
          )
        ],
      ),
    );
  }

  Widget _priorityItem(String label, int count, Color color) {
    return Column(
      children: [
        Text("$count", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: kPriority2Color, size: 20),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _getAdvice(List<Task> tasks) {
    if (tasks.isEmpty) return "Bắt đầu thêm công việc để tôi có thể phân tích giúp bạn!";
    int selfImp = tasks.where((t) => ['Học tập', 'Sức khỏe', 'Phát triển bản thân', 'Study', 'Health', 'Self-Improvement'].contains(t.category)).length;
    double ratio = selfImp / tasks.length;
    if (ratio > 0.7) return "Bạn đang rèn luyện rất căng thẳng. Đừng quên dành 15p nghỉ ngơi mỗi giờ nhé! ☕";
    if (ratio < 0.2) return "Có vẻ bạn đang hơi nuông chiều bản thân. Hãy thử bắt đầu với một task nhỏ nào! 💪";
    return "Tuyệt vời! Bạn đang duy trì phong độ rất ổn định và cân bằng.";
  }

  int _calculateStreak(List<Task> done) {
    if (done.isEmpty) return 0;
    Set<String> days = done.map((t) => DateFormat('yyyy-MM-dd').format(t.dueDate ?? t.createdAt)).toSet();
    int s = 0; DateTime d = DateTime.now();
    if (!days.contains(DateFormat('yyyy-MM-dd').format(d))) d = d.subtract(const Duration(days: 1));
    while (days.contains(DateFormat('yyyy-MM-dd').format(d))) { s++; d = d.subtract(const Duration(days: 1)); }
    return s;
  }

  int _calculateScore(List<Task> tasks) {
    if (tasks.isEmpty) return 0;
    double tot = 0, comp = 0;
    for (var t in tasks) {
      double w = (t.priority == 'High' || t.priority == 'Cao') ? 3 : ((t.priority == 'Medium' || t.priority == 'Trung bình') ? 2 : 1);
      tot += w; if (t.isDone) comp += w;
    }
    return (comp / tot * 100).toInt();
  }
}
