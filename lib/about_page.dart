import 'package:flutter/material.dart';
import 'main.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const List<Map<String, String>> _members = [
    {
      'name': 'Đào Minh Khương',
      'role': 'Trưởng nhóm',
      'image': 'assets/members/khuong.jpg',
    },
    {
      'name': 'Huỳnh Hải Nam',
      'role': 'Lập trình viên',
      'image': 'assets/members/nam.jpg',
    },
    {
      'name': 'Chu Văn Lương',
      'role': 'Lập trình viên',
      'image': 'assets/members/luong.jpg',
    },
    {
      'name': 'Phí Đình Huynh',
      'role': 'Thiết kế',
      'image': 'assets/members/huynh.jpg',
    },
    {
      'name': 'Đinh Quang Huy',
      'role': 'Kiểm thử',
      'image': 'assets/members/huy.jpg',
    },
  ];

  Widget _buildMemberItem(BuildContext context, Map<String, String> member) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [kPriority2Color, kPriority2Color.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: kPriority2Color.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 38,
            backgroundColor: kBackgroundColor,
            backgroundImage: AssetImage(member['image']!),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black.withOpacity(0.2), width: 1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          member['name']!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          member['role']!,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child, Color? accentColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor ?? kPriority2Color, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Giới thiệu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildSectionCard(
              title: 'Nhóm phát triển',
              icon: Icons.groups_rounded,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(child: _buildMemberItem(context, _members[0])),
                      Expanded(child: _buildMemberItem(context, _members[1])),
                      Expanded(child: _buildMemberItem(context, _members[2])),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 110, child: _buildMemberItem(context, _members[3])),
                      const SizedBox(width: 20),
                      SizedBox(width: 110, child: _buildMemberItem(context, _members[4])),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionCard(
              title: 'Giới thiệu ứng dụng',
              icon: Icons.info_outline_rounded,
              accentColor: kPriority1Color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Task Management App là ứng dụng hỗ trợ quản lý công việc cá nhân hằng ngày một cách trực quan và dễ sử dụng.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ứng dụng cho phép người dùng tạo task, chỉnh sửa nội dung, theo dõi tiến độ và sắp xếp công việc theo mức độ ưu tiên. Với giao diện tối hiện đại, người dùng có thể tập trung hơn vào kế hoạch cá nhân và nâng cao hiệu suất học tập hoặc làm việc.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phiên bản 1.0.0',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.2),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kPriority1Color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Phiên bản mới nhất',
                          style: TextStyle(color: kPriority1Color, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
