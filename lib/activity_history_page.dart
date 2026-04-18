import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'task_model.dart';
import 'task_service.dart';
import 'task_detail_page.dart';

const kBackgroundColor = Color(0xFF1B2333);
const kCardColor = Color(0xFF263042);
const kAccentColor = Color(0xFFC9E8A2);
const kPriority2Color = Color(0xFF4ED9F5);
const kPriority3Color = Color(0xFFCDC1D8);
const kTextSoft = Color(0xFF94A3B8);

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  final TaskService _taskService = TaskService();
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  String _searchQuery = "";
  String _selectedCategory = "Tất cả";

  final List<String> _categories = ["Tất cả", "Công việc", "Học tập", "Cá nhân", "Sức khỏe"];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Công việc': case 'Work': return Icons.work_outline;
      case 'Học tập': case 'Study': return Icons.menu_book_rounded;
      case 'Cá nhân': case 'Personal': return Icons.person_outline;
      case 'Sức khỏe': case 'Health': return Icons.favorite_border_rounded;
      default: return Icons.category_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Công việc': case 'Work': return kPriority2Color;
      case 'Học tập': case 'Study': return kPriority3Color;
      case 'Sức khỏe': case 'Health': return Colors.redAccent;
      default: return kAccentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Lịch sử hoạt động", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildCategoryFilter(),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _taskService.getTasks(user?.uid ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: kAccentColor));
                }
                
                final allTasks = snapshot.data ?? [];
                
                // Lọc theo điều kiện
                var filteredTasks = allTasks.where((task) {
                  final isDone = task.isDone;
                  final taskDate = task.dueDate ?? task.createdAt;
                  final isRecent = taskDate.isAfter(threeMonthsAgo);
                  
                  // Lọc theo tìm kiếm tiêu đề
                  final matchesSearch = task.title.toLowerCase().contains(_searchQuery.toLowerCase());
                  
                  // Lọc theo chủ đề (Hỗ trợ cả Tiếng Anh và Tiếng Việt cũ)
                  bool matchesCategory = _selectedCategory == "Tất cả";
                  if (!matchesCategory) {
                    if (_selectedCategory == "Công việc") matchesCategory = task.category == "Công việc" || task.category == "Work";
                    else if (_selectedCategory == "Học tập") matchesCategory = task.category == "Học tập" || task.category == "Study";
                    else if (_selectedCategory == "Cá nhân") matchesCategory = task.category == "Cá nhân" || task.category == "Personal";
                    else if (_selectedCategory == "Sức khỏe") matchesCategory = task.category == "Sức khỏe" || task.category == "Health";
                  }
                  
                  // Lọc theo khoảng ngày
                  bool matchesDateRange = true;
                  if (_selectedDateRange != null) {
                    final dateToCheck = DateTime(taskDate.year, taskDate.month, taskDate.day);
                    final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
                    final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);
                    matchesDateRange = (dateToCheck.isAtSameMomentAs(start) || dateToCheck.isAfter(start)) &&
                                     (dateToCheck.isAtSameMomentAs(end) || dateToCheck.isBefore(end));
                  }
                  
                  return isDone && isRecent && matchesSearch && matchesDateRange && matchesCategory;
                }).toList();

                filteredTasks.sort((a, b) => (b.dueDate ?? b.createdAt).compareTo(a.dueDate ?? a.createdAt));

                if (filteredTasks.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryItem(filteredTasks[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Tìm kiếm tiêu đề nhiệm vụ...",
              hintStyle: const TextStyle(color: kTextSoft),
              prefixIcon: const Icon(Icons.search, color: kTextSoft),
              filled: true,
              fillColor: kCardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: const Icon(Icons.clear, color: kTextSoft),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = "");
                    },
                  )
                : null,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _selectedDateRange != null ? kAccentColor.withOpacity(0.5) : Colors.transparent),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range_rounded, color: _selectedDateRange != null ? kAccentColor : kTextSoft, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDateRange == null 
                        ? "Lọc theo khoảng ngày" 
                        : "${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}",
                      style: TextStyle(
                        color: _selectedDateRange == null ? kTextSoft : Colors.white,
                        fontSize: 14,
                        fontWeight: _selectedDateRange != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (_selectedDateRange != null)
                    GestureDetector(
                      onTap: () => setState(() => _selectedDateRange = null),
                      child: const Icon(Icons.cancel, color: kTextSoft, size: 18),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected ? kAccentColor : kCardColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: isSelected ? [BoxShadow(color: kAccentColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
              ),
              alignment: Alignment.center,
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? Colors.black : kTextSoft,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: kAccentColor,
              onPrimary: Colors.black,
              surface: kCardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  Widget _buildHistoryItem(Task task) {
    final color = _getCategoryColor(task.category);
    final icon = _getCategoryIcon(task.category);

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailPage(task: task))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Thanh màu bên cạnh để phân loại chủ đề
                Container(width: 6, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        // Icon chủ đề
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 18),
                        // Nội dung Task
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _translateCategory(task.category),
                                      style: TextStyle(color: color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.event_available, color: kTextSoft, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    task.dueDate != null ? DateFormat('dd/MM/yyyy').format(task.dueDate!) : "N/A",
                                    style: const TextStyle(color: kTextSoft, fontSize: 13),
                                  ),
                                  const SizedBox(width: 15),
                                  const Icon(Icons.access_time, color: kTextSoft, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    task.startTime != null ? DateFormat('HH:mm').format(task.startTime!) : "--:--",
                                    style: const TextStyle(color: kTextSoft, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white12, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _translateCategory(String category) {
    switch (category) {
      case 'Work': return 'Công việc';
      case 'Study': return 'Học tập';
      case 'Personal': return 'Cá nhân';
      case 'Health': return 'Sức khỏe';
      default: return category;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: kCardColor, shape: BoxShape.circle),
            child: const Icon(Icons.history_rounded, size: 60, color: kTextSoft),
          ),
          const SizedBox(height: 20),
          const Text("Không tìm thấy kết quả", style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text("Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm", style: TextStyle(color: kTextSoft, fontSize: 14)),
        ],
      ),
    );
  }
}
