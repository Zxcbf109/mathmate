import 'package:flutter/material.dart';
import 'package:mathmate/models/user_profile.dart';
import 'package:mathmate/services/user_profile_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final UserProfileService _profileService = UserProfileService();
  late TextEditingController _nicknameCtrl;
  late TextEditingController _bioCtrl;
  String _grade = 'Math Explorer';

  static const List<String> _grades = [
    'Math Explorer',
    '小学',
    '初中',
    '高中',
    '大学',
  ];

  @override
  void initState() {
    super.initState();
    final p = _profileService.profile;
    _nicknameCtrl = TextEditingController(text: p.nickname);
    _bioCtrl = TextEditingController(text: p.bio);
    _grade = p.grade;
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑个人资料'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存'),
          ),
        ],
      ),
      backgroundColor: cs.surfaceContainerLowest,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar placeholder
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primaryContainer,
              ),
              child: Icon(Icons.person, size: 44, color: cs.primary),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('头像更换功能开发中')),
                );
              },
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('更换头像'),
            ),
          ),
          const SizedBox(height: 20),
          // Nickname
          Text('昵称', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameCtrl,
            decoration: InputDecoration(
              hintText: '请输入昵称',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: cs.surface,
            ),
          ),
          const SizedBox(height: 20),
          // Grade
          Text('年级', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _grade,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: cs.surface,
            ),
            items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _grade = v);
            },
          ),
          const SizedBox(height: 20),
          // Bio
          Text('个性签名', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '写一句话介绍自己...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: cs.surface,
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    _profileService.save(UserProfile(
      nickname: _nicknameCtrl.text.trim().isEmpty ? 'MathMate_User' : _nicknameCtrl.text.trim(),
      avatar: _profileService.profile.avatar,
      grade: _grade,
      bio: _bioCtrl.text.trim(),
    ));
    if (mounted) Navigator.pop(context);
  }
}
