import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/login_screen.dart';
import 'screens/main_app_layout.dart';
import 'models/recipe.dart';
// import 'models/ingredient_item.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Hive
  await Hive.initFlutter();

  // Đăng ký adapter
  Hive.registerAdapter(IngredientItemAdapter());
  Hive.registerAdapter(RecipeAdapter());

  // Mở box lưu trữ công thức
  await Hive.openBox<Recipe>('recipes');

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
