import 'package:flutter/material.dart';
import 'main.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const List<Map<String, String>> _members = [
    {
      'name': 'Đào Minh Khương',
      'image': 'assets/members/khuong.jpg',
    },
    {
      'name': 'Huỳnh Hải Nam',
      'image': 'assets/members/nam.jpg',
    },
    {
      'name': 'Chu Văn Lương',
      'image': 'assets/members/luong.jpg',
    },
    {
      'name': 'Phí Đình Huynh',
      'image': 'assets/members/huynh.jpg',
    },
    {
      'name': 'Đinh Quang Huy',
      'image': 'assets/members/huy.jpg',
    },
  ];

  Widget _buildMemberItem(Map<String, String> member) {
    return SizedBox(
      width: 96,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: kPriority2Color.withOpacity(0.45),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: kCardColor,
              backgroundImage: AssetImage(member['image']!),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 20,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                member['name']!,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'About',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.groups_rounded, color: kPriority2Color),
                        SizedBox(width: 10),
                        Text(
                          'Nhóm phát triển',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Hàng trên: 3 người
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMemberItem(_members[0]),
                        _buildMemberItem(_members[1]),
                        _buildMemberItem(_members[2]),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Hàng dưới: 2 người
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMemberItem(_members[3]),
                        const SizedBox(width: 28),
                        _buildMemberItem(_members[4]),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: kPriority1Color),
                        SizedBox(width: 10),
                        Text(
                          'Giới thiệu ứng dụng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Task Management App là ứng dụng hỗ trợ quản lý công việc cá nhân hằng ngày một cách trực quan và dễ sử dụng.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Ứng dụng cho phép người dùng tạo task, chỉnh sửa nội dung, theo dõi tiến độ và sắp xếp công việc theo mức độ ưu tiên. Với giao diện tối hiện đại, người dùng có thể tập trung hơn vào kế hoạch cá nhân và nâng cao hiệu suất học tập hoặc làm việc.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.7,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Phiên bản 1.0.0',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
