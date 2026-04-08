import 'package:flutter/material.dart';
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

class EditTaskPage extends StatefulWidget {
  final Task task;

  const EditTaskPage({
    super.key,
    required this.task,
  });

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final TaskService _taskService = TaskService();

  late TextEditingController _titleController;
  late TextEditingController _descController;

  DateTime? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

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

  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.task.title);
    _descController = TextEditingController(text: widget.task.description);
    _selectedDay = widget.task.dueDate;
    _startTime = widget.task.startTime != null
        ? TimeOfDay.fromDateTime(widget.task.startTime!)
        : null;
    _endTime = widget.task.endTime != null
        ? TimeOfDay.fromDateTime(widget.task.endTime!)
        : null;

    _selectedIcon = _getInitialIcon();
  }

  IconData _getInitialIcon() {
    if (widget.task.iconCode != null) {
      for (final icon in taskIcons) {
        if (icon.codePoint == widget.task.iconCode) {
          return icon;
        }
      }
    }
    return _guessIconFromTitle(widget.task.title);
  }

  IconData _guessIconFromTitle(String title) {
    final t = title.toLowerCase();

    if (t.contains('chạy') || t.contains('run') || t.contains('thể dục')) {
      return Icons.directions_run;
    }
    if (t.contains('gym') || t.contains('tập')) return Icons.fitness_center;
    if (t.contains('học') || t.contains('study') || t.contains('bài')) {
      return Icons.book;
    }
    if (t.contains('ngủ') || t.contains('sleep')) return Icons.bed;
    if (t.contains('làm') || t.contains('work')) return Icons.work;
    if (t.contains('ăn') || t.contains('uống')) return Icons.restaurant;
    if (t.contains('code') || t.contains('lập trình')) return Icons.code;
    if (t.contains('phim')) return Icons.movie;
    if (t.contains('mua')) return Icons.shopping_cart;
    if (t.contains('cafe')) return Icons.local_cafe;

    return taskIcons.isNotEmpty ? taskIcons.first : Icons.assignment_outlined;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay ?? DateTime.now(),
      firstDate: DateTime(2000),
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

    final title = _titleController.text.trim();
    final description = _descController.text.trim();

    if (title.isEmpty) {
      _showMessage("Vui lòng nhập tiêu đề task");
      return;
    }

    if (_selectedDay == null || _startTime == null || _endTime == null) {
      _showMessage("Vui lòng chọn đầy đủ ngày và giờ");
      return;
    }

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

    if (!end.isAfter(start)) {
      _showMessage("Giờ kết thúc phải lớn hơn giờ bắt đầu");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isOverlapping = await _taskService.isTimeOverlapping(
        widget.task.userId,
        start,
        end,
        excludeId: widget.task.id,
      );

      if (isOverlapping) {
        _showMessage("Thời gian này bị trùng với task khác!");
        setState(() => _isLoading = false);
        return;
      }

      final updatedTask = Task(
        id: widget.task.id,
        userId: widget.task.userId,
        title: title,
        description: description,
        createdAt: widget.task.createdAt,
        dueDate: _selectedDay,
        startTime: start,
        endTime: end,
        isDone: widget.task.isDone,
        iconCode: _selectedIcon.codePoint,
      );

      await _taskService.updateTask(updatedTask);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cập nhật task thành công"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showMessage("Có lỗi xảy ra khi cập nhật task");
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

  String _formatPreviewDate() {
    if (_selectedDay == null) return "Chưa chọn ngày";
    return DateFormat('EEE, dd MMM yyyy').format(_selectedDay!);
  }

  String _formatPreviewTime() {
    if (_startTime == null || _endTime == null) return "Chưa chọn thời gian";
    return "${_startTime!.format(context)} - ${_endTime!.format(context)}";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
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
                      _buildPreviewCard(),
                      const SizedBox(height: 24),
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
                      _buildSectionLabel("Ngày"),
                      _buildPickerTile(
                        icon: Icons.calendar_today_rounded,
                        text: _selectedDay == null
                            ? "Chọn ngày"
                            : DateFormat('dd/MM/yyyy').format(_selectedDay!),
                        onTap: _pickDate,
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
                "Edit Task",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "Cập nhật lại công việc của bạn",
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

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF162033),
            const Color(0xFF1B2A40),
            kGlowColor.withOpacity(0.12),
          ],
        ),
        border: Border.all(
          color: kGlowColor.withOpacity(0.20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: kGlowColor.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kGlowColor.withOpacity(0.10),
              border: Border.all(
                color: kGlowColor.withOpacity(0.45),
                width: 1,
              ),
            ),
            child: Hero(
              tag: 'task_icon_${widget.task.id}',
              transitionOnUserGestures: true,
              child: Material(
                color: Colors.transparent,
                child: Icon(
                  _selectedIcon,
                  color: kAccentSoft,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _titleController.text.trim().isEmpty
                ? "Tên task"
                : _titleController.text.trim(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _formatPreviewDate(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatPreviewTime(),
            style: const TextStyle(
              color: kAccentColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: (_) => setState(() {}),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
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
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: kGlowColor.withOpacity(0.16),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
                    : null,
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
            boxShadow: [
              BoxShadow(
                color: kGlowColor.withOpacity(0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
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
              "LƯU THAY ĐỔI",
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