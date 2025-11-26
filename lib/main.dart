import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/login_screen.dart';
import 'screens/main_app_layout.dart';
import 'models/recipe.dart';
// import 'models/ingredient_item.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Hive
  await Hive.initFlutter();
  Hive.registerAdapter(IngredientItemAdapter());
  Hive.registerAdapter(RecipeAdapter());
  await Hive.openBox<Recipe>('recipes');

  // Khởi tạo sqflite cho desktop (nếu dùng database SQLite)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Không cần làm gì cho SharedPreferences trên desktop, plugin mới tự setup

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
      // Mở màn login trước, sau khi login sẽ push MainAppLayout
      home: const LoginScreen(),
    );
  }
}
