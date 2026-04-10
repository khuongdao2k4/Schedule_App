import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'task_model.dart';
import 'task_service.dart';

const kBackgroundColor = Color(0xFF0F172A);
const kCardColor = Color(0xFF182235);
const kInputColor = Color(0xFF1E293B);
const kGlowColor = Color(0xFF4ED9F5);
const kAccentColor = Color(0xFF7DD3FC);
const kAccentSoft = Color(0xFFC9E8A2);
const kTextSoft = Color(0xFF94A3B8);

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TaskService _taskService = TaskService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _estController = TextEditingController(text: '30');

  DateTime? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  String _selectedPriority = 'Medium';
  String _selectedCategory = 'Personal';

  final List<String> _categories = [
    'Work', 
    'Study', 
    'Personal', 
    'Health', 
    'Entertainment', // Vui chơi
    'Self-Improvement', // Rèn luyện bản thân
    'Finance', 
    'Other'
  ];
  final List<String> _priorities = ['Low', 'Medium', 'High'];

  final List<IconData> taskIcons = [
    Icons.work,
    Icons.book,
    Icons.code,
    Icons.directions_run,
    Icons.fitness_center,
    Icons.restaurant,
    Icons.movie,
    Icons.shopping_cart,
    Icons.local_cafe,
    Icons.bed,
    Icons.assignment,
    Icons.flight,
  ];

  IconData _selectedIcon = Icons.assignment_outlined;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _selectedDay = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? (_startTime ?? TimeOfDay.now()),
    );

    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _saveTask() async {
    if (_isLoading) return;

    final user = FirebaseAuth.instance.currentUser;
    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    final estMinutes = int.tryParse(_estController.text) ?? 30;

    if (user == null) {
      _showMessage("Không tìm thấy người dùng đăng nhập");
      return;
    }

    if (title.isEmpty) {
      _showMessage("Vui lòng nhập tiêu đề task");
      return;
    }

    if (_selectedDay == null || _startTime == null || _endTime == null) {
      _showMessage("Vui lòng chọn đầy đủ ngày và giờ");
      return;
    }

    final now = DateTime.now();
    final start = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    final end = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      _endTime!.hour,
      _endTime!.minute,
    );

    if (start.isBefore(now)) {
      _showMessage("Thời gian bắt đầu không được ở trong quá khứ!");
      return;
    }

    if (!end.isAfter(start)) {
      _showMessage("Giờ kết thúc phải lớn hơn giờ bắt đầu");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isOverlapping = await _taskService.isTimeOverlapping(
        user.uid,
        start,
        end,
      );

      if (isOverlapping) {
        _showMessage("Thời gian này đã có task khác, vui lòng chọn khung giờ khác!");
        setState(() => _isLoading = false);
        return;
      }

      final task = Task(
        userId: user.uid,
        title: title,
        description: description,
        createdAt: DateTime.now(),
        dueDate: _selectedDay,
        startTime: start,
        endTime: end,
        isDone: false,
        iconCode: _selectedIcon.codePoint,
        priority: _selectedPriority,
        category: _selectedCategory,
        estimatedMinutes: estMinutes,
      );

      await _taskService.addTask(task);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tạo task thành công"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showMessage("Có lỗi xảy ra khi tạo task");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _estController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B1220),
              Color(0xFF111827),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 22),
                      _buildSectionLabel("Tiêu đề"),
                      _buildTextField(
                        controller: _titleController,
                        hint: "Nhập tiêu đề task...",
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel("Mô tả"),
                      _buildTextField(
                        controller: _descController,
                        hint: "Mô tả task...",
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel("Phân loại"),
                                _buildDropdown(_categories, _selectedCategory, (val) {
                                  setState(() => _selectedCategory = val!);
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel("Độ ưu tiên"),
                                _buildDropdown(_priorities, _selectedPriority, (val) {
                                  setState(() => _selectedPriority = val!);
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel("Ngày"),
                                _buildPickerTile(
                                  icon: Icons.calendar_today_rounded,
                                  text: _selectedDay == null
                                      ? "Chọn ngày"
                                      : DateFormat('dd/MM/yyyy').format(_selectedDay!),
                                  onTap: _pickDate,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionLabel("Dự kiến (phút)"),
                                _buildTextField(
                                  controller: _estController,
                                  hint: "VD: 30",
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel("Thời gian"),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPickerTile(
                              icon: Icons.schedule_rounded,
                              text: _startTime == null
                                  ? "Bắt đầu"
                                  : _startTime!.format(context),
                              onTap: _pickStartTime,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPickerTile(
                              icon: Icons.alarm_on_rounded,
                              text: _endTime == null
                                  ? "Kết thúc"
                                  : _endTime!.format(context),
                              onTap: _pickEndTime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel("Biểu tượng"),
                      const SizedBox(height: 8),
                      _buildHorizontalIconPicker(),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: _isLoading ? null : () => Navigator.pop(context),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Task",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Tạo công việc mới cho bạn",
                style: TextStyle(
                  color: kTextSoft,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kInputColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: kGlowColor.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.white24,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String selected, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: kInputColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kGlowColor.withOpacity(0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          dropdownColor: kCardColor,
          icon: const Icon(Icons.arrow_drop_down, color: kGlowColor),
          style: const TextStyle(color: Colors.white, fontSize: 14.5),
          isExpanded: true,
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: kInputColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: kGlowColor.withOpacity(0.12),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: kGlowColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalIconPicker() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: taskIcons.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final icon = taskIcons[index];
          final isSelected = _selectedIcon.codePoint == icon.codePoint;

          return GestureDetector(
            onTap: _isLoading
                ? null
                : () {
              setState(() {
                _selectedIcon = icon;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? kGlowColor.withOpacity(0.18)
                    : kInputColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? kGlowColor
                      : Colors.white.withOpacity(0.08),
                  width: isSelected ? 1.2 : 1,
                ),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? kAccentSoft : Colors.white70,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                kGlowColor.withOpacity(0.95),
                kAccentColor.withOpacity(0.88),
              ],
            ),
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveTask,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.black,
              ),
            )
                : const Text(
              "TẠO TASK",
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
