import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tunify/logic/music_provider.dart';
import 'package:tunify/UI/home_page.dart';

class LocalLoginPage extends StatefulWidget {
  const LocalLoginPage({super.key});

  @override
  State<LocalLoginPage> createState() => _LocalLoginPageState();
}

class _LocalLoginPageState extends State<LocalLoginPage> {
  final TextEditingController _userCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();
  bool _isRegistering = false; // Chế độ: false = Đăng nhập, true = Đăng ký
  String _message = "";

  void _submit() async {
    final provider = Provider.of<MusicProvider>(context, listen: false);
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      setState(() => _message = "Vui lòng nhập tài khoản và mật khẩu");
      return;
    }

    if (_isRegistering) {
      // --- XỬ LÝ ĐĂNG KÝ ---
      bool success = await provider.register(user, pass);
      if (success) {
        setState(() {
          _message = "Đăng ký thành công! Hãy đăng nhập.";
          _isRegistering = false; // Chuyển về màn hình login
          _passCtrl.clear();
        });
      } else {
        setState(() => _message = "Tài khoản đã tồn tại. Chọn tên khác.");
      }
    } else {
      // --- XỬ LÝ ĐĂNG NHẬP ---
      bool success = await provider.login(user, pass);
      if (success) {
        if (!mounted) return;
        // Chuyển sang trang chủ và xóa trang login khỏi stack
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomePage())
        );
      } else {
        setState(() => _message = "Sai tài khoản hoặc mật khẩu.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              const Icon(Icons.music_note_rounded, size: 100, color: Color(0xFF1DB954)),
              const SizedBox(height: 20),
              Text(
                _isRegistering ? "ĐĂNG KÝ TUNIFY" : "ĐĂNG NHẬP TUNIFY",
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Ô nhập tài khoản
              TextField(
                controller: _userCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Tên tài khoản",
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF282828),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 20),

              // Ô nhập mật khẩu
              TextField(
                controller: _passCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Mật khẩu",
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF282828),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                ),
              ),

              const SizedBox(height: 15),

              // Thông báo lỗi/thành công
              if (_message.isNotEmpty)
                Text(_message, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),

              const SizedBox(height: 25),

              // Nút Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1DB954),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: _submit,
                  child: Text(
                    _isRegistering ? "ĐĂNG KÝ" : "ĐĂNG NHẬP",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Nút chuyển đổi chế độ
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRegistering = !_isRegistering;
                    _message = "";
                    _userCtrl.clear();
                    _passCtrl.clear();
                  });
                },
                child: Text(
                  _isRegistering
                      ? "Đã có tài khoản? Đăng nhập ngay"
                      : "Chưa có tài khoản? Đăng ký mới",
                  style: const TextStyle(color: Colors.white70),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}