import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'group_model.dart';
import 'group_service.dart';
import 'group_chat_page.dart';
import 'main.dart'; // For colors

class GroupListPage extends StatefulWidget {
  const GroupListPage({super.key});

  @override
  State<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends State<GroupListPage> {
  final GroupService _groupService = GroupService();
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  void _showCreateGroupDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: kBackgroundColor.withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
            side: BorderSide(color: kPriority1Color.withOpacity(0.1)),
          ),
          title: const Text("TẠO KHÔNG GIAN MỚI", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2)
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              hintText: "Tên nhóm làm việc...",
              hintStyle: const TextStyle(color: Colors.white24),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY", style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && user != null) {
                  await _groupService.createGroup(nameController.text, user!.uid);
                  if (!mounted) return;
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPriority1Color,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("KHỞI TẠO", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          // Background Mesh Gradients
          Positioned(
            top: -80, right: -80,
            child: _BlurredOrb(color: kPriority1Color.withOpacity(0.12), size: 250),
          ),
          Positioned(
            bottom: 100, left: -100,
            child: _BlurredOrb(color: kPriority2Color.withOpacity(0.08), size: 300),
          ),
          
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 140.0, // Giảm chiều cao để tiêu đề cân đối hơn
                collapsedHeight: 70.0,
                pinned: true,
                backgroundColor: kBackgroundColor.withOpacity(0.9),
                elevation: 0,
                leadingWidth: 60,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 12, right: 20), // Chỉnh padding tiêu đề
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Nhóm làm việc", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                      Text("Quản lý dự án và cộng tác", 
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Tìm kiếm dự án...",
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3), size: 18),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ),

              // Group List
              StreamBuilder<List<Group>>(
                stream: _groupService.getGroups(user?.uid ?? ''),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: kPriority1Color, strokeWidth: 2)));
                  }

                  final groups = (snapshot.data ?? []).where((g) => 
                    g.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                  if (groups.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text("TRỐNG", style: TextStyle(color: Colors.white.withOpacity(0.1), letterSpacing: 5, fontSize: 14, fontWeight: FontWeight.w900)),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _GroupListItem(
                          group: groups[index],
                          color: [kPriority1Color, kPriority2Color, kPriority3Color, Colors.blueAccent][index % 4],
                        ),
                        childCount: groups.length,
                      ),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),
      floatingActionButton: _ModernFAB(onPressed: _showCreateGroupDialog),
    );
  }
}

class _GroupListItem extends StatelessWidget {
  final Group group;
  final Color color;

  const _GroupListItem({required this.group, required this.color});

  @override
  Widget build(BuildContext context) {
    String lastTime = "";
    if (group.lastMessageTime != null) {
      lastTime = DateFormat('HH:mm').format(group.lastMessageTime!);
    } else {
      lastTime = DateFormat('HH:mm').format(group.createdAt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatPage(group: group))),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: Row(
              children: [
                // Avatar Nhóm
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [color.withOpacity(0.8), color],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      group.name.isNotEmpty ? group.name[0].toUpperCase() : "?",
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Thông tin nhóm
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(group.name, 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: 0.2)),
                          ),
                          Text(lastTime, style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        group.lastMessage ?? "Chưa có tin nhắn mới",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: group.lastMessage != null ? Colors.white60 : Colors.white24,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Member Facepile
                      _MemberFacepile(memberCount: group.members.length, color: color),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberFacepile extends StatelessWidget {
  final int memberCount;
  final Color color;
  const _MemberFacepile({required this.memberCount, required this.color});

  @override
  Widget build(BuildContext context) {
    int displayCount = memberCount > 3 ? 3 : memberCount;
    int extraCount = memberCount - 3;

    return Row(
      children: [
        SizedBox(
          height: 24,
          width: (displayCount * 18.0) + (extraCount > 0 ? 30 : 0),
          child: Stack(
            children: [
              for (int i = 0; i < displayCount; i++)
                Positioned(
                  left: i * 14.0,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: kBackgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: kBackgroundColor, width: 2),
                    ),
                    child: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2 + (i * 0.2)),
                      child: Icon(Icons.person_rounded, size: 12, color: color.withOpacity(0.8)),
                    ),
                  ),
                ),
              if (extraCount > 0)
                Positioned(
                  left: displayCount * 14.0,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2F33),
                      shape: BoxShape.circle,
                      border: Border.all(color: kBackgroundColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        "+$extraCount",
                        style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "$memberCount thành viên",
          style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _ModernFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _ModernFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64, width: 64,
      decoration: BoxDecoration(
        color: kPriority1Color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: kPriority1Color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: const Icon(Icons.add_rounded, color: Colors.black, size: 32),
        ),
      ),
    );
  }
}

class _BlurredOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurredOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), child: Container(color: Colors.transparent)),
    );
  }
}
