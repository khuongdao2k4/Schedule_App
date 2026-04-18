import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'task_model.dart';
import 'task_service.dart';
import 'user_service.dart';

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
  final UserService _userService = UserService();

  late TextEditingController _titleController;
  late TextEditingController _descController;
  final TextEditingController _emailController = TextEditingController();

  DateTime? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  final List<String> _assignees = [];
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  final List<IconData> taskIcons = [
    Icons.work_rounded,
    Icons.menu_book_rounded,
    Icons.code_rounded,
    Icons.terminal_rounded,
    Icons.edit_note_rounded,
    Icons.lightbulb_outline_rounded,
    Icons.fitness_center_rounded,
    Icons.directions_run_rounded,
    Icons.self_improvement_rounded,
    Icons.pool_rounded,
    Icons.pedal_bike_rounded,
    Icons.sports_soccer_rounded,
    Icons.restaurant_rounded,
    Icons.local_cafe_rounded,
    Icons.celebration_rounded,
    Icons.movie_filter_rounded,
    Icons.videogame_asset_rounded,
    Icons.music_note_rounded,
    Icons.camera_alt_rounded,
    Icons.home_rounded,
    Icons.shopping_cart_rounded,
    Icons.payments_rounded,
    Icons.cleaning_services_rounded,
    Icons.pets_rounded,
    Icons.favorite_rounded,
    Icons.alarm_rounded,
    Icons.notifications_active_rounded,
    Icons.flight_takeoff_rounded,
    Icons.map_rounded,
    Icons.assignment_rounded,
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

    _assignees.addAll(widget.task.assignees);
    _selectedIcon = _getInitialIcon();
    
    // Kiểm tra quyền sửa ngay khi vào trang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.task.userId != _currentUserId) {
        _showNoPermissionDialog();
      }
    });
  }

  void _showNoPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: kCardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Không có quyền", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Chỉ người tạo nhiệm vụ mới có quyền chỉnh sửa thông tin này.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
              Navigator.pop(context); // Quay lại trang trước
            },
            child: const Text("Đồng ý", style: TextStyle(color: kGlowColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  IconData _getInitialIcon() {
    if (widget.task.iconCode != null) {
      for (final icon in taskIcons) {
        if (icon.codePoint == widget.task.iconCode) {
          return icon;
        }
      }
      return IconData(widget.task.iconCode!, fontFamily: 'MaterialIcons');
    }
    return Icons.assignment_rounded;
  }

  Future<void> _addUserByEmail() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final userData = await _userService.getUserByEmail(email);
      if (userData == null) {
        _showMessage("Không tìm thấy người dùng với email này!");
      } else {
        final uid = userData['uid'] as String;
        if (_assignees.contains(uid)) {
          _showMessage("Người dùng này đã có trong danh sách!");
        } else {
          setState(() {
            _assignees.add(uid);
            _emailController.clear();
          });
          _showMessage("Đã thêm người tham gia!");
        }
      }
    } catch (e) {
      _showMessage("Lỗi khi tìm kiếm người dùng");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: kGlowColor, onPrimary: Colors.black, surface: kCardColor, onSurface: Colors.white),
        ),
        child: child!,
      ),
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
    
    // Kiểm tra quyền lần cuối trước khi lưu
    if (widget.task.userId != _currentUserId) {
      _showMessage("Bạn không có quyền sửa nhiệm vụ này!");
      return;
    }

    final title = _titleController.text.trim();
    final description = _descController.text.trim();

    if (title.isEmpty) {
      _showMessage("Vui lòng nhập tiêu đề nhiệm vụ");
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
      _showMessage("Giờ kết thúc phải sau giờ bắt đầu");
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
        _showMessage("Thời gian này bị trùng với nhiệm vụ khác!");
        setState(() => _isLoading = false);
        return;
      }

      final updatedTask = widget.task.copyWith(
        title: title,
        description: description,
        dueDate: _selectedDay,
        startTime: start,
        endTime: end,
        iconCode: _selectedIcon.codePoint,
        assignees: _assignees,
      );

      await _taskService.updateTask(updatedTask);

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cập nhật nhiệm vụ thành công"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showMessage("Có lỗi xảy ra khi cập nhật nhiệm vụ");
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
    return DateFormat('dd/MM/yyyy').format(_selectedDay!);
  }

  String _formatPreviewTime() {
    if (_startTime == null || _endTime == null) return "Chưa chọn thời gian";
    return "${_startTime!.format(context)} - ${_endTime!.format(context)}";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nếu không phải chủ sở hữu, trả về Scaffold trống hoặc đang tải trong khi chờ dialog hiện lên
    if (widget.task.userId != _currentUserId) {
      return const Scaffold(backgroundColor: kBackgroundColor, body: Center(child: CircularProgressIndicator()));
    }

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
                        hint: "Nhập tiêu đề nhiệm vụ...",
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel("Mô tả"),
                      _buildTextField(
                        controller: _descController,
                        hint: "Mô tả nhiệm vụ...",
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
                      const SizedBox(height: 25),
                      _buildSectionLabel("Thành viên thực hiện"),
                      _buildAddMemberField(),
                      const SizedBox(height: 15),
                      _buildAssigneesList(),
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
                "Sửa Nhiệm vụ",
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
            child: Icon(
              _selectedIcon,
              color: kAccentSoft,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _titleController.text.trim().isEmpty
                ? "Tên nhiệm vụ"
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

  Widget _buildAddMemberField() {
    return Container(
      decoration: BoxDecoration(
        color: kInputColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGlowColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: "Nhập email người tham gia...",
                hintStyle: TextStyle(color: Colors.white24),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _addUserByEmail(),
            ),
          ),
          IconButton(
            onPressed: _addUserByEmail,
            icon: const Icon(Icons.person_add_alt_1_rounded, color: kGlowColor),
          ),
        ],
      ),
    );
  }

  Widget _buildAssigneesList() {
    if (_assignees.isEmpty) return const SizedBox.shrink();
    return Column(
      children: List.generate(_assignees.length, (index) {
        final uid = _assignees[index];
        bool isCreator = uid == widget.task.userId;
        return FutureBuilder<Map<String, dynamic>?>(
          future: _userService.getUserData(uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final userData = snapshot.data!;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kCardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: userData['photo'] != null ? NetworkImage(userData['photo']) : null,
                    child: userData['photo'] == null ? const Icon(Icons.person, size: 20) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userData['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(isCreator ? "Người tạo nhiệm vụ" : "Người tham gia", style: TextStyle(color: isCreator ? kAccentSoft : kTextSoft, fontSize: 11)),
                      ],
                    ),
                  ),
                  if (!isCreator)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => setState(() => _assignees.remove(uid)),
                    ),
                ],
              ),
            );
          },
        );
      }),
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
