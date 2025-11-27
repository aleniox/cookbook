import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo sqflite cho desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // TODO: nếu cần, bạn có thể tạo bảng SQLite ban đầu ở đây
  // await RecipeService.initDatabase();

  runApp(const RecipeApp());
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sách Nấu Ăn Flutter',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(), // Mở login trước
    );
  }
}
