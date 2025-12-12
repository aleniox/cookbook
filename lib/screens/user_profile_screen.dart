import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  bool _loading = false;
  String _joinedText = '';
  File? _avatarFile;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final avatar = prefs.getString('avatarPath') ?? '';
    File? avatarFile;
    if (avatar.isNotEmpty) {
      final f = File(avatar);
      if (await f.exists()) avatarFile = f;
    }
    setState(() {
      _emailCtrl.text = prefs.getString('email') ?? '';
      _nameCtrl.text = prefs.getString('displayName') ?? '';
      // optional: show when user first used app (if stored)
      final joined = prefs.getString('joinedAt');
      _joinedText = joined ?? '';
      _avatarFile = avatarFile;
      _avatarPath = avatarFile?.path;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('displayName', _nameCtrl.text.trim());
    // optionally set joinedAt when first saved
    if ((prefs.getString('joinedAt') ?? '').isEmpty) {
      await prefs.setString('joinedAt', DateTime.now().toIso8601String());
      _joinedText = DateTime.now().toIso8601String();
    }
    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu thông tin người dùng.')),
    );
  }

  Future<void> _clearCredentials() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xóa thông tin đăng nhập?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    await prefs.remove('password');
    if (!mounted) return;
    setState(() {
      _emailCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xoá thông tin đăng nhập.')),
    );
  }

  String _initials(String name, String email) {
    if (name.isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return (parts[0][0] + parts.last[0]).toUpperCase();
      }
      return parts.first[0].toUpperCase();
    }
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }

  Color _avatarColor(String seed) {
    final hash = seed.runes.fold<int>(0, (p, c) => p + c);
    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.deepOrange,
      Colors.purple,
      Colors.blueGrey,
      Colors.green,
      Colors.brown,
    ];
    return colors[hash % colors.length];
  }

  Future<void> _copyEmailToClipboard() async {
    if (_emailCtrl.text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _emailCtrl.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép email vào clipboard.')),
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;
      final appDir = await getApplicationDocumentsDirectory();
      final idx = picked.path.lastIndexOf('.');
      final ext = idx != -1 ? picked.path.substring(idx) : '';
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}$ext';
      final saved = await File(picked.path).copy('${appDir.path}/$fileName');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('avatarPath', saved.path);
      if (!mounted) return;
      setState(() {
        _avatarFile = saved;
        _avatarPath = saved.path;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tải ảnh: $e')));
    }
  }

  Future<void> _removeAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('avatarPath');
    if (_avatarFile != null) {
      try {
        if (await _avatarFile!.exists()) await _avatarFile!.delete();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _avatarFile = null;
      _avatarPath = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa avatar.')));
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final initials = _initials(name, email);
    final avatarBg = _avatarColor(name.isNotEmpty ? name : email);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        centerTitle: true,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: avatarBg,
                              backgroundImage: _avatarFile != null
                                  ? FileImage(_avatarFile!)
                                  : null,
                              child: _avatarFile == null
                                  ? Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(FocusNode());
                                  showModalBottomSheet<void>(
                                    context: context,
                                    builder: (ctx) => Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Avatar',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.photo_library,
                                            ),
                                            title: const Text('Chọn ảnh'),
                                            onTap: () {
                                              Navigator.of(ctx).pop();
                                              _pickAvatar();
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.person),
                                            title: const Text(
                                              'Dùng chữ cái đầu (mặc định)',
                                            ),
                                            onTap: () {
                                              Navigator.of(ctx).pop();
                                              _removeAvatar();
                                            },
                                          ),
                                          if (_avatarFile != null) ...[
                                            const Divider(height: 12),
                                            ListTile(
                                              leading: const Icon(
                                                Icons.delete_forever,
                                                color: Colors.redAccent,
                                              ),
                                              title: const Text(
                                                'Xóa ảnh',
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                              onTap: () {
                                                Navigator.of(ctx).pop();
                                                _removeAvatar();
                                              },
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name.isNotEmpty ? name : 'Người dùng',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_joinedText.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Tham gia: ${_joinedText.split('T').first}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tên hiển thị',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.done,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Vui lòng nhập tên hiển thị';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _emailCtrl,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Sao chép email',
                                onPressed: _copyEmailToClipboard,
                                icon: const Icon(Icons.copy),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: _loading ? null : _saveProfile,
                                  child: _loading
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Lưu thay đổi'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _clearCredentials,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Xóa đăng nhập'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Useful actions
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Đổi mật khẩu'),
                        subtitle: const Text(
                          'Dùng chức năng thay đổi mật khẩu nếu có',
                        ),
                        onTap: () {
                          // placeholder: show info
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Chức năng đổi mật khẩu chưa được tích hợp.',
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.help_outline),
                        title: const Text('Trợ giúp & Hỗ trợ'),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mở trang trợ giúp...'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Phiên bản ứng dụng: 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
