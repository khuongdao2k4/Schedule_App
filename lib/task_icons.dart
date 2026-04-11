import 'package:flutter/material.dart';

class TaskIcons {
  static const List<IconData> icons = [
    // Công việc & Học tập
    Icons.work_rounded,
    Icons.menu_book_rounded,
    Icons.code_rounded,
    Icons.terminal_rounded,
    Icons.edit_note_rounded,
    Icons.lightbulb_outline_rounded,
    Icons.computer_rounded,
    Icons.history_edu_rounded,
    
    // Sức khỏe & Thể thao
    Icons.fitness_center_rounded,
    Icons.directions_run_rounded,
    Icons.self_improvement_rounded, // Yoga/Thiền
    Icons.pool_rounded,
    Icons.pedal_bike_rounded,
    Icons.sports_soccer_rounded,
    Icons.hiking_rounded,
    Icons.monitor_heart_rounded,
    
    // Đời sống & Giải trí
    Icons.restaurant_rounded,
    Icons.local_cafe_rounded,
    Icons.celebration_rounded, // Vui chơi
    Icons.movie_filter_rounded,
    Icons.videogame_asset_rounded,
    Icons.music_note_rounded,
    Icons.camera_alt_rounded,
    Icons.brush_rounded,
    Icons.auto_awesome_rounded,
    
    // Gia đình & Cá nhân
    Icons.home_rounded,
    Icons.shopping_cart_rounded,
    Icons.payments_rounded, // Tài chính
    Icons.cleaning_services_rounded,
    Icons.pets_rounded,
    Icons.favorite_rounded,
    Icons.family_restroom_rounded,
    Icons.child_care_rounded,
    
    // Khác
    Icons.alarm_rounded,
    Icons.notifications_active_rounded,
    Icons.flight_takeoff_rounded,
    Icons.map_rounded,
    Icons.assignment_rounded,
    Icons.mail_outline_rounded,
    Icons.call_rounded,
  ];

  static IconData getIconByTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('chạy') || t.contains('run') || t.contains('thể dục')) return Icons.directions_run_rounded;
    if (t.contains('gym') || t.contains('tập') || t.contains('tạ')) return Icons.fitness_center_rounded;
    if (t.contains('học') || t.contains('bài') || t.contains('study') || t.contains('đọc')) return Icons.menu_book_rounded;
    if (t.contains('ngủ') || t.contains('sleep')) return Icons.bedtime_rounded;
    if (t.contains('làm') || t.contains('work') || t.contains('việc')) return Icons.work_rounded;
    if (t.contains('ăn') || t.contains('uống') || t.contains('eat') || t.contains('cơm')) return Icons.restaurant_rounded;
    if (t.contains('code') || t.contains('lập trình') || t.contains('dev')) return Icons.code_rounded;
    if (t.contains('phim') || t.contains('movie') || t.contains('xem')) return Icons.movie_filter_rounded;
    if (t.contains('mua') || t.contains('shop') || t.contains('chợ')) return Icons.shopping_cart_rounded;
    if (t.contains('cafe') || t.contains('cà phê') || t.contains('nước')) return Icons.local_cafe_rounded;
    if (t.contains('thiền') || t.contains('yoga')) return Icons.self_improvement_rounded;
    if (t.contains('game') || t.contains('chơi')) return Icons.videogame_asset_rounded;
    if (t.contains('tiền') || t.contains('pay') || t.contains('bank')) return Icons.payments_rounded;
    if (t.contains('dọn') || t.contains('vệ sinh')) return Icons.cleaning_services_rounded;
    if (t.contains('bay') || t.contains('du lịch')) return Icons.flight_takeoff_rounded;
    
    return Icons.assignment_rounded;
  }
}
