import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'task_model.dart';
import 'task_service.dart';
import 'my_tasks_page.dart';
import 'task_icons.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final TaskService _taskService = TaskService();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final Color kPriority1Color = const Color(0xFFC9E8A2);
  final Color kPriority2Color = const Color(0xFF4ED9F5);
  final Color kPriority3Color = const Color(0xFFCDC1D8);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1B2333) : Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Lịch trình",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Task>>(
        stream: _taskService.getTasks(user?.uid ?? ''),
        builder: (context, snapshot) {
          final allTasks = snapshot.data ?? [];
          final selectedTasks = allTasks.where((t) {
            if (t.dueDate == null) return false;
            return isSameDay(t.dueDate, _selectedDay);
          }).toList();

          return Column(
            children: [
              _buildCalendarCard(allTasks, isDark),
              const SizedBox(height: 16),
              Expanded(
                child: _buildTaskListSection(selectedTasks, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendarCard(List<Task> allTasks, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF263042) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        locale: 'vi_VN',
        rowHeight: 52,
        availableGestures: AvailableGestures.all,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        eventLoader: (day) {
          return allTasks.where((t) => isSameDay(t.dueDate, day)).toList();
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: kPriority2Color),
          rightChevronIcon: Icon(Icons.chevron_right, color: kPriority2Color),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          weekendTextStyle: TextStyle(color: kPriority3Color),
          todayDecoration: BoxDecoration(
            color: kPriority2Color.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: kPriority2Color,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: BoxDecoration(
            color: kPriority1Color,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          markerDecoration: BoxDecoration(
            color: kPriority2Color,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 1,
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isNotEmpty) {
              return Positioned(
                bottom: 6,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: kPriority2Color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildTaskListSection(List<Task> selectedTasks, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161D2B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSameDay(_selectedDay, DateTime.now())
                    ? "Hôm nay"
                    : DateFormat('dd MMMM, yyyy').format(_selectedDay),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MyTasksPage(initialDate: _selectedDay),
                    ),
                  );
                },
                child: Text(
                  "Xem chi tiết",
                  style: TextStyle(color: kPriority2Color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: selectedTasks.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    itemCount: selectedTasks.length,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemBuilder: (context, index) {
                      return _buildTaskMiniItem(selectedTasks[index], isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskMiniItem(Task task, bool isDark) {
    final IconData displayIcon = task.isDone
        ? Icons.check_circle_rounded
        : (task.iconCode != null
            ? IconData(task.iconCode!, fontFamily: 'MaterialIcons')
            : TaskIcons.getIconByTitle(task.title));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF263042) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (task.isDone ? kPriority1Color : kPriority2Color).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              displayIcon,
              color: task.isDone ? kPriority1Color : kPriority2Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black,
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  task.startTime != null
                      ? "${DateFormat('HH:mm').format(task.startTime!)} - ${DateFormat('HH:mm').format(task.endTime!)}"
                      : "Không có thời gian",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          if (task.isDone)
            Icon(Icons.check_circle, color: kPriority1Color, size: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 64,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "Không có nhiệm vụ nào",
            style: TextStyle(
              color: Colors.grey.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
