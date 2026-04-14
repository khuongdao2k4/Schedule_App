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

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _estController = TextEditingController(text: '30');
  final TextEditingController _emailController = TextEditingController();

  DateTime? _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  String _selectedPriority = 'Medium';
  String _selectedCategory = 'Personal';

  // Danh sách người tham gia (Lưu UID)
  final List<String> _assignees = [];
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  final List<String> _categories = [
    'Work', 
    'Study', 
    'Personal', 
    'Health', 
    'Entertainment', 
    'Self-Improvement', 
    'Finance', 
    'Other'
  ];
  final List<String> _priorities = ['Low', 'Medium', 'High'];

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

  IconData _selectedIcon = Icons.assignment_rounded;

  @override
  void initState() {
    super.initState();
    // Người tạo task mặc định nằm trong danh sách
    if (_currentUserId.isNotEmpty) {
      _assignees.add(_currentUserId);
    }
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
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => _buildPickerTheme(child!),
    );
    if (picked != null) setState(() => _selectedDay = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) => _buildPickerTheme(child!),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? (_startTime ?? TimeOfDay.now()),
      builder: (context, child) => _buildPickerTheme(child!),
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  Widget _buildPickerTheme(Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: kGlowColor,
          onPrimary: Colors.black,
          surface: kCardColor,
          onSurface: Colors.white,
        ),
      ),
      child: child,
    );
  }

  Future<void> _saveTask() async {
    if (_isLoading) return;

    final user = FirebaseAuth.instance.currentUser;
    final title = _titleController.text.trim();
    if (user == null || title.isEmpty || _selectedDay == null || _startTime == null || _endTime == null) {
      _showMessage("Vui lòng điền đầy đủ thông tin!");
      return;
    }

    final start = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, _startTime!.hour, _startTime!.minute);
    final end = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day, _endTime!.hour, _endTime!.minute);

    if (!end.isAfter(start)) {
      _showMessage("Giờ kết thúc phải sau giờ bắt đầu!");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final isOverlapping = await _taskService.isTimeOverlapping(user.uid, start, end);
      if (isOverlapping) {
        _showMessage("Bị trùng lịch với task khác!");
        setState(() => _isLoading = false);
        return;
      }

      final task = Task(
        userId: user.uid,
        title: title,
        description: _descController.text.trim(),
        dueDate: _selectedDay,
        startTime: start,
        endTime: end,
        iconCode: _selectedIcon.codePoint,
        priority: _selectedPriority,
        category: _selectedCategory,
        estimatedMinutes: int.tryParse(_estController.text) ?? 30,
        assignees: _assignees,
      );

      await _taskService.addTask(task);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showMessage("Lỗi khi tạo task");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: kCardColor, behavior: SnackBarBehavior.floating));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _estController.dispose();
    _emailController.dispose();
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
            colors: [Color(0xFF0B1220), Color(0xFF111827), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 25),
                      _buildSectionLabel("Tiêu đề"),
                      _buildTextField(_titleController, "Nhập tiêu đề task..."),
                      const SizedBox(height: 20),
                      _buildSectionLabel("Mô tả"),
                      _buildTextField(_descController, "Mô tả ngắn gọn...", maxLines: 3),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _buildSectionLabel("Phân loại"),
                            _buildDropdown(_categories, _selectedCategory, (v) => setState(() => _selectedCategory = v!)),
                          ])),
                          const SizedBox(width: 15),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _buildSectionLabel("Độ ưu tiên"),
                            _buildDropdown(_priorities, _selectedPriority, (v) => setState(() => _selectedPriority = v!)),
                          ])),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _buildSectionLabel("Ngày"),
                            _buildPickerTile(Icons.calendar_today_rounded, _selectedDay == null ? "Chọn ngày" : DateFormat('dd/MM/yyyy').format(_selectedDay!), _pickDate),
                          ])),
                          const SizedBox(width: 15),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            _buildSectionLabel("Dự kiến (phút)"),
                            _buildTextField(_estController, "30", keyboardType: TextInputType.number),
                          ])),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSectionLabel("Thời gian"),
                      Row(
                        children: [
                          Expanded(child: _buildPickerTile(Icons.schedule_rounded, _startTime == null ? "Bắt đầu" : _startTime!.format(context), _pickStartTime)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildPickerTile(Icons.alarm_on_rounded, _endTime == null ? "Kết thúc" : _endTime!.format(context), _pickEndTime)),
                        ],
                      ),
                      const SizedBox(height: 25),
                      _buildSectionLabel("Biểu tượng"),
                      const SizedBox(height: 10),
                      _buildIconGrid(),
                      const SizedBox(height: 25),
                      _buildSectionLabel("Thành viên thực hiện"),
                      _buildAddMemberField(),
                      const SizedBox(height: 15),
                      _buildAssigneesList(),
                      const SizedBox(height: 30),
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
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(width: 15),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Create Task", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text("Tạo công việc mới cho bạn", style: TextStyle(color: kTextSoft, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 10), child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)));

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: kInputColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: kGlowColor.withOpacity(0.1))),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white24), border: InputBorder.none, contentPadding: const EdgeInsets.all(16)),
      ),
    );
  }

  Widget _buildAddMemberField() {
    return Container(
      decoration: BoxDecoration(color: kInputColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: kGlowColor.withOpacity(0.1))),
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
        bool isCreator = uid == _currentUserId;
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

  Widget _buildDropdown(List<String> items, String selected, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: kInputColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: kGlowColor.withOpacity(0.1))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          dropdownColor: kCardColor,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kGlowColor),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          isExpanded: true,
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPickerTile(IconData icon, String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kInputColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: kGlowColor.withOpacity(0.1))),
        child: Row(children: [Icon(icon, color: kGlowColor, size: 20), const SizedBox(width: 10), Text(text, style: const TextStyle(color: Colors.white, fontSize: 14))]),
      ),
    );
  }

  Widget _buildIconGrid() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kInputColor.withOpacity(0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 10, crossAxisSpacing: 10),
        itemCount: taskIcons.length,
        itemBuilder: (context, index) {
          final icon = taskIcons[index];
          final isSelected = _selectedIcon.codePoint == icon.codePoint;
          return GestureDetector(
            onTap: () => setState(() => _selectedIcon = icon),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? kGlowColor : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected ? [BoxShadow(color: kGlowColor.withOpacity(0.3), blurRadius: 8)] : null,
              ),
              child: Icon(icon, size: 20, color: isSelected ? Colors.black : Colors.white60),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: kGlowColor,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
          shadowColor: kGlowColor.withOpacity(0.3),
        ),
        child: _isLoading 
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
          : const Text("TẠO TASK", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
    );
  }
}
