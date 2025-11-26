import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_app_layout.dart';

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

  final Map<String, String> _users = {};

  @override
  void initState() {
    super.initState();
    _autoLogin();
  }

  // Tự đăng nhập nếu có dữ liệu đã lưu
  Future<void> _autoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString("email");
    final savedPassword = prefs.getString("password");

    if (savedEmail != null && savedPassword != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainAppLayout()),
      );
    }
  }

  // Lưu tài khoản
  Future<void> _saveAccount(String email, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("email", email);
    await prefs.setString("password", password);
  }

  void _toggleForm() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isLogin) {
      if (_users.containsKey(email) && _users[email] == password) {
        // Lưu tài khoản sau khi đăng nhập thành công
        await _saveAccount(email, password);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đăng nhập thành công")));

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
      if (_users.containsKey(email)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Email đã tồn tại")));
      } else {
        _users[email] = password;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đăng ký thành công")));
        _toggleForm();
      }
    }
  }

  void _forgotPassword() {
    final email = _emailController.text.trim();
    if (_users.containsKey(email)) {
      _users[email] = "123456";
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu tạm thời: 123456")),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Email chưa đăng ký")));
    }
  }

  // ------------------- UI -------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),
      body: Center(
        child: Container(
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
            textInputAction:
                TextInputAction.next, // ⬅ nhấn Enter sẽ chuyển focus
            onFieldSubmitted: (_) {
              FocusScope.of(context).nextFocus(); // ⬅ chuyển xuống mật khẩu
            },
            decoration: _inputStyle("Email"),
            validator: (v) =>
                v == null || !v.contains("@") ? "Email không hợp lệ" : null,
          ),

          const SizedBox(height: 16),

          // Password + Eye Button
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done, // ⬅ Enter = hoàn tất
            onFieldSubmitted: (_) => _submit(), // ⬅ Enter để đăng nhập
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

          // BUTTON
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade700,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  shadowColor: Colors.transparent,
                  backgroundColor: Colors.transparent,
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
