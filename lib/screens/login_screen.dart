import 'package:flutter/material.dart';
import '../helpers/login_helper.dart';
import 'main_app_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _autoLogin();
  }

  // ---------------- AUTO LOGIN ----------------
  Future<void> _autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString("email");

    if (savedEmail != null && savedEmail.isNotEmpty) {
      // Đã login trước → vào thẳng app
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainAppLayout()),
      );
    }
  }

  // ---------------- SUBMIT ----------------
  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isLogin) {
      // ---- LOGIN ----
      final user = await DBHelper.getUser(email);

      if (user != null && user['password'] == password) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("email", email);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng nhập thành công")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainAppLayout()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sai email hoặc mật khẩu")),
        );
      }
    } else {
      // ---- REGISTER ----
      final user = await DBHelper.getUser(email);

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email đã tồn tại")),
        );
      } else {
        await DBHelper.insertUser(email, password);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng ký thành công")),
        );

        _toggleForm();
      }
    }
  }

  // ---------------- FORGOT PASSWORD ----------------
  void _forgotPassword() async {
    final email = _emailController.text.trim();
    final user = await DBHelper.getUser(email);

    if (user != null) {
      await DBHelper.updatePassword(email, "123456");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu tạm thời: 123456")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email chưa đăng ký")),
      );
    }
  }

  // ---------------- TOGGLE FORM ----------------
  void _toggleForm() {
    setState(() {
      _isLogin = !_isLogin;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),
      body: Center(
        child: SizedBox(
          width: 380,
          height: 480,
          child: Card(
            elevation: 8,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(child: _buildForm()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Text(
            _isLogin ? "Chào mừng trở lại 👋" : "Tạo tài khoản mới",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _isLogin ? "Đăng nhập để tiếp tục" : "Chỉ mất vài bước đơn giản",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 26),

          // Email
          TextFormField(
            controller: _emailController,
            decoration: _inputStyle("Email"),
            validator: (v) =>
                v == null || !v.contains("@") ? "Email không hợp lệ" : null,
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _inputStyle("Mật khẩu").copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            validator: (v) =>
                v == null || v.length < 6 ? "Mật khẩu tối thiểu 6 ký tự" : null,
          ),
          const SizedBox(height: 28),

          // Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade700
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _isLogin ? "Đăng nhập" : "Đăng ký",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: _toggleForm,
            child: Text(
              _isLogin
                  ? "Chưa có tài khoản? Đăng ký"
                  : "Đã có tài khoản? Đăng nhập",
            ),
          ),

          if (_isLogin)
            TextButton(
              onPressed: _forgotPassword,
              child: const Text("Quên mật khẩu?"),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
